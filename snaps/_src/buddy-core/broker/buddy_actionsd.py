#!/usr/bin/env python3
"""
Buddy-OS Actions Daemon (broker/buddy_actionsd.py)

This is a lightweight internal HTTP daemon used by Buddy-OS UI + Buddy runtime to:
- enforce policy gates (allowlist/blacklist + consent)
- execute a small, explicitly allowed set of actions
- expose provider model listings (starting with Ollama Local)

This update is **backward compatible** with your current file:
- Keeps existing endpoints:
    GET  /health
    GET  /providers/ollama-local/models
    GET  /policy/reload
    POST /execute
- Keeps your policy.json shape (version/access_preset/allow_mode/allowlist/blacklist/no_memory_zones/consent/re_auth_required)
- Keeps audit logging (but improves redaction)

Adds (non-breaking) endpoints for UI plumbing:
    GET  /policy                 (current policy)
    POST /policy                 (update policy fields safely)
    GET  /providers/status        (single place for UI to read provider reachability/model lists)
    GET  /providers/ollama-local/tags  (raw-ish tags info from Ollama for richer dropdowns)

Shell execution:
- Still **disabled by default** for safety, BUT can be enabled via env var:
    BUDDY_ENABLE_SHELL=1
- Even when enabled, policy + consent still apply.

Environment variables:
- BUDDY_POLICY_PATH   (default: <repo>/broker/policy.json)
- BUDDY_AUDIT_PATH    (default: <repo>/broker/audit.log.jsonl)
- BUDDY_HOST          (default: 127.0.0.1)
- BUDDY_PORT          (default: 8765)
- BUDDY_ENABLE_SHELL  (default: 0)
- BUDDY_OLLAMA_URL    (default: http://127.0.0.1:11434/api/tags)
"""

import json
import os
import re
import subprocess
import sys
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


# -----------------------------
# Time / JSON helpers
# -----------------------------

def now_utc() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

def read_json(path: str):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def write_json(path: str, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, sort_keys=True)
        f.write("\n")
    os.replace(tmp, path)

def abspath(p: str) -> str:
    return os.path.abspath(os.path.expanduser(p))

def path_is_under(p: str, root: str) -> bool:
    p = os.path.normpath(p)
    root = os.path.normpath(root)
    if p == root:
        return True
    return p.startswith(root + os.sep)


# -----------------------------
# Redaction (improved, recursive)
# -----------------------------

_SECRET_PATTERNS = [
    # GitHub tokens
    (re.compile(r"(ghp_[A-Za-z0-9]{20,})"), "[REDACTED_GITHUB_TOKEN]"),
    # OpenAI-ish keys
    (re.compile(r"(sk-[A-Za-z0-9]{20,})"), "[REDACTED_OPENAI_KEY]"),
    # Google API keys
    (re.compile(r"(AIza[0-9A-Za-z\-_]{20,})"), "[REDACTED_GOOGLE_KEY]"),
    # JWTs
    (re.compile(r"([A-Za-z0-9_\-]{24,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,})"), "[REDACTED_JWT]"),
    # Generic bearer tokens
    (re.compile(r"(?i)\bBearer\s+[A-Za-z0-9._\-]{10,}"), "Bearer [REDACTED]"),
    # Generic api_key=... patterns
    (re.compile(r"(?i)\b(api[_-]?key|token|secret)\b\s*[:=]\s*([^\s\"']{8,})"), r"\1=[REDACTED]"),
]

def redact_secrets(obj):
    """
    Recursively redact secrets from strings inside dicts/lists.
    """
    if isinstance(obj, str):
        s = obj
        for pat, rep in _SECRET_PATTERNS:
            s = pat.sub(rep, s)
        return s
    if isinstance(obj, list):
        return [redact_secrets(x) for x in obj]
    if isinstance(obj, dict):
        return {k: redact_secrets(v) for k, v in obj.items()}
    return obj


# -----------------------------
# Default policy
# -----------------------------

def default_policy(repo_root: str):
    home = os.path.expanduser("~")
    return {
        "version": "0.1",
        "access_preset": "restricted",
        "allow_mode": "allowlist",
        "allowlist": [repo_root],
        "blacklist": [os.path.join(home, ".ssh"), os.path.join(home, ".gnupg")],
        "no_memory_zones": [os.path.join(home, ".ssh"), os.path.join(home, ".gnupg")],
        "consent": {
            "mkdir": "allow",
            "write_file": "ask",
            "list_dir": "allow",
            "open_url": "allow",
            "launch_app": "ask",
            "shell": "deny",
        },
        "re_auth_required": {
            "shell": True
        }
    }


# -----------------------------
# Actions Engine
# -----------------------------

class ActionsEngine:
    def __init__(self, repo_root: str, policy_path: str, audit_path: str):
        self.repo_root = repo_root
        self.policy_path = policy_path
        self.audit_path = audit_path
        self.policy = self.load_policy()

        self.enable_shell = os.environ.get("BUDDY_ENABLE_SHELL", "0").strip() in ("1", "true", "yes", "on")
        self.ollama_tags_url = os.environ.get("BUDDY_OLLAMA_URL", "http://127.0.0.1:11434/api/tags").strip()

    # ---- Policy ----

    def load_policy(self):
        if os.path.exists(self.policy_path):
            try:
                return read_json(self.policy_path)
            except Exception:
                return default_policy(self.repo_root)
        return default_policy(self.repo_root)

    def save_policy(self):
        write_json(self.policy_path, self.policy)

    def reload_policy(self):
        self.policy = self.load_policy()
        return self.policy

    def get_policy(self):
        return self.policy

    def update_policy(self, patch: dict):
        """
        Safe-ish policy patching for UI: only allow updating known top-level keys.
        """
        if not isinstance(patch, dict):
            return False, "patch must be object", None

        allowed_keys = {
            "access_preset",
            "allow_mode",
            "allowlist",
            "blacklist",
            "no_memory_zones",
            "consent",
            "re_auth_required",
        }

        new_pol = dict(self.policy)
        for k, v in patch.items():
            if k not in allowed_keys:
                continue
            new_pol[k] = v

        # Normalize/clean paths in lists
        for key in ("allowlist", "blacklist", "no_memory_zones"):
            if key in new_pol and isinstance(new_pol[key], list):
                cleaned = []
                for item in new_pol[key]:
                    if isinstance(item, str) and item.strip():
                        cleaned.append(abspath(item.strip()))
                new_pol[key] = cleaned

        # Normalize allow_mode
        if "allow_mode" in new_pol:
            if str(new_pol["allow_mode"]).lower() not in ("allowlist", "blacklist", "open"):
                new_pol["allow_mode"] = "allowlist"

        # Normalize consent
        if "consent" in new_pol and isinstance(new_pol["consent"], dict):
            c = {}
            for ak, av in new_pol["consent"].items():
                if not isinstance(ak, str):
                    continue
                v = str(av).lower()
                if v not in ("allow", "ask", "deny"):
                    v = "ask"
                c[ak] = v
            new_pol["consent"] = c

        self.policy = new_pol
        self.save_policy()
        return True, "", self.policy

    # ---- Audit ----

    def audit(self, entry: dict):
        os.makedirs(os.path.dirname(self.audit_path), exist_ok=True)
        safe = redact_secrets(entry)
        safe["timestamp"] = now_utc()
        with open(self.audit_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(safe, ensure_ascii=False) + "\n")

    # ---- Policy checks ----

    def check_path(self, target_path: str):
        p = abspath(target_path)
        allow_mode = str(self.policy.get("allow_mode", "allowlist")).lower()
        allowlist = [abspath(x) for x in self.policy.get("allowlist", []) if isinstance(x, str)]
        blacklist = [abspath(x) for x in self.policy.get("blacklist", []) if isinstance(x, str)]

        # Blacklist wins
        for b in blacklist:
            if path_is_under(p, b):
                return False, f"Path is blacklisted: {b}"

        # Allowlist mode
        if allow_mode == "allowlist":
            for a in allowlist:
                if path_is_under(p, a):
                    return True, ""
            return False, "Path not in allowlist"

        # Blacklist mode/open mode: already handled blacklist; allow otherwise
        return True, ""

    def consent_rule(self, action: str) -> str:
        return str(self.policy.get("consent", {}).get(action, "ask")).lower()

    def require_reauth(self, action: str) -> bool:
        return bool(self.policy.get("re_auth_required", {}).get(action, False))

    # ---- Action implementations ----

    def exec_mkdir(self, params: dict):
        path = params.get("path", "")
        if not path:
            return False, "missing path", None
        ok, msg = self.check_path(path)
        if not ok:
            return False, msg, None
        p = abspath(path)
        os.makedirs(p, exist_ok=True)
        return True, "", {"path": p}

    def exec_write_file(self, params: dict):
        path = params.get("path", "")
        content = params.get("content", "")
        if not path:
            return False, "missing path", None
        ok, msg = self.check_path(path)
        if not ok:
            return False, msg, None
        p = abspath(path)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "w", encoding="utf-8") as f:
            f.write(str(content))
        return True, "", {"path": p, "bytes": len(str(content).encode("utf-8"))}

    def exec_list_dir(self, params: dict):
        path = params.get("path", "")
        if not path:
            return False, "missing path", None
        ok, msg = self.check_path(path)
        if not ok:
            return False, msg, None
        p = abspath(path)
        if not os.path.isdir(p):
            return False, "not a directory", None
        items = sorted(os.listdir(p))
        return True, "", {"path": p, "items": items}

    def exec_open_url(self, params: dict):
        url = params.get("url", "")
        if not url:
            return False, "missing url", None
        subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True, "", {"url": url}

    def exec_launch_app(self, params: dict):
        """
        Backward compatible:
        - accepts cmd as list (existing behavior)
        - ALSO accepts cmd as string (runs via bash -lc)
        """
        cmd = params.get("cmd", [])
        if isinstance(cmd, str) and cmd.strip():
            subprocess.Popen(["bash", "-lc", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True, "", {"cmd": ["bash", "-lc", cmd]}

        if not isinstance(cmd, list) or not cmd or not all(isinstance(x, str) for x in cmd):
            return False, "missing cmd list (or cmd string)", None

        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True, "", {"cmd": cmd}

    def exec_shell(self, params: dict):
        """
        Shell is disabled by default unless BUDDY_ENABLE_SHELL=1.
        Even if enabled, policy consent still applies (and you can keep it denied by policy).
        """
        cmd = params.get("cmd", "")
        timeout_s = params.get("timeout_s", 90)
        if not cmd:
            return False, "missing cmd", None

        if not self.enable_shell:
            return False, "shell disabled (set BUDDY_ENABLE_SHELL=1 to enable)", None

        try:
            timeout_s = float(timeout_s)
        except Exception:
            timeout_s = 90.0

        try:
            p = subprocess.run(
                ["bash", "-lc", str(cmd)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=timeout_s,
            )
            # cap output to keep logs sane
            out = (p.stdout or "")[-20000:]
            err = (p.stderr or "")[-20000:]
            return True, "", {
                "cmd": str(cmd),
                "returncode": p.returncode,
                "stdout": out,
                "stderr": err,
            }
        except subprocess.TimeoutExpired:
            return False, "command timed out", None

    # ---- Provider: Ollama Local ----

    def _fetch_ollama_tags(self):
        req = Request(self.ollama_tags_url, headers={"Accept": "application/json"})
        with urlopen(req, timeout=3) as r:
            return json.loads(r.read().decode("utf-8", errors="replace"))

    def list_ollama_local_models(self):
        """
        Backward compatible return shape:
            (ok:bool, models:[str], err:str)
        """
        try:
            data = self._fetch_ollama_tags()
            models = []
            for m in data.get("models", []) or []:
                name = m.get("name") or m.get("model")
                if isinstance(name, str) and name.strip():
                    models.append(name.strip())
            models = sorted(set(models))
            return True, models, ""
        except (URLError, HTTPError, ValueError, json.JSONDecodeError) as e:
            return False, [], str(e)

    def list_ollama_local_models_info(self):
        """
        Rich model info for UI (non-breaking additive).
        """
        try:
            data = self._fetch_ollama_tags()
            out = []
            for m in data.get("models", []) or []:
                name = m.get("name") or m.get("model")
                if not isinstance(name, str) or not name.strip():
                    continue
                out.append({
                    "name": name.strip(),
                    "modified_at": m.get("modified_at"),
                    "size": m.get("size"),
                    "digest": m.get("digest"),
                    "details": m.get("details", {}),
                })
            # stable sort by name
            out.sort(key=lambda x: x.get("name", ""))
            return True, out, ""
        except (URLError, HTTPError, ValueError, json.JSONDecodeError) as e:
            return False, [], str(e)

    # ---- Execute router ----

    def execute(self, action: str, params: dict, consent: bool, reason: str):
        action_id = str(uuid.uuid4())
        rule = self.consent_rule(action)

        if rule == "deny":
            self.audit({"action_id": action_id, "action": action, "reason": reason, "result": "denied"})
            return {"ok": False, "action_id": action_id, "error": "denied by policy"}

        if rule == "ask" and not consent:
            self.audit({"action_id": action_id, "action": action, "reason": reason, "result": "consent_required"})
            return {"ok": False, "action_id": action_id, "consent_required": True, "message": "consent required by policy"}

        fn = {
            "mkdir": self.exec_mkdir,
            "write_file": self.exec_write_file,
            "list_dir": self.exec_list_dir,
            "open_url": self.exec_open_url,
            "launch_app": self.exec_launch_app,
            "shell": self.exec_shell,
        }.get(action)

        if not fn:
            self.audit({"action_id": action_id, "action": action, "reason": reason, "result": "error", "error": "unknown action"})
            return {"ok": False, "action_id": action_id, "error": "unknown action"}

        ok, err, result = fn(params)
        if ok:
            self.audit({"action_id": action_id, "action": action, "reason": reason, "result": "ok", "params": params})
            return {"ok": True, "action_id": action_id, "result": result}

        self.audit({"action_id": action_id, "action": action, "reason": reason, "result": "error", "error": err, "params": params})
        return {"ok": False, "action_id": action_id, "error": err}

    # ---- Provider status aggregator (UI convenience) ----

    def providers_status(self):
        """
        Single UI call to populate dropdowns + show reachability.
        For now:
        - ollama-local: real
        - other providers: scaffold only (connected False, models [])
        """
        st = {"ok": True, "timestamp": now_utc(), "providers": {}}

        ok, models, err = self.list_ollama_local_models()
        st["providers"]["ollama-local"] = {
            "enabled": True,
            "connected": bool(ok),
            "reachable": bool(ok),
            "error": "" if ok else err,
            "models": models,
        }

        # Scaffolds (UI-friendly; real auth wiring later)
        for pid in ("ollama-cloud", "openai", "gemini", "claude", "grok"):
            st["providers"][pid] = {
                "enabled": False,
                "connected": False,
                "reachable": False,
                "error": "",
                "models": [],
            }

        return st


# -----------------------------
# HTTP Handler
# -----------------------------

class Handler(BaseHTTPRequestHandler):
    server_version = "buddy-actions/0.1"

    def _send(self, code: int, obj: dict):
        data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _read_json(self, max_bytes: int = 1_000_000):
        """
        Prevent accidental giant payloads.
        """
        n = int(self.headers.get("Content-Length", "0") or "0")
        if n <= 0:
            return {}
        if n > max_bytes:
            raise ValueError("payload too large")
        raw = self.rfile.read(n)
        return json.loads(raw.decode("utf-8", errors="replace") or "{}")

    def do_GET(self):
        # health
        if self.path == "/health":
            self._send(200, {"ok": True, "service": "buddy-actions", "version": "0.1"})
            return

        # providers - ollama local (names list)
        if self.path == "/providers/ollama-local/models":
            ok, models, err = self.server.engine.list_ollama_local_models()
            if ok:
                # additive: also include models_info for UI-rich dropdowns
                ok2, info, err2 = self.server.engine.list_ollama_local_models_info()
                payload = {"ok": True, "provider": "ollama-local", "models": models}
                payload["models_info"] = info if ok2 else []
                if not ok2 and err2:
                    payload["models_info_error"] = err2
                self._send(200, payload)
            else:
                self._send(503, {"ok": False, "provider": "ollama-local", "error": err, "models": [], "models_info": []})
            return

        # providers - ollama local raw tags (useful for debugging)
        if self.path == "/providers/ollama-local/tags":
            try:
                data = self.server.engine._fetch_ollama_tags()
                self._send(200, {"ok": True, "provider": "ollama-local", "tags": data})
            except (URLError, HTTPError, ValueError, json.JSONDecodeError) as e:
                self._send(503, {"ok": False, "provider": "ollama-local", "error": str(e), "tags": {}})
            return

        # providers status (UI convenience)
        if self.path == "/providers/status":
            self._send(200, self.server.engine.providers_status())
            return

        # policy (current)
        if self.path == "/policy":
            self._send(200, {"ok": True, "policy": self.server.engine.get_policy()})
            return

        # policy reload (existing)
        if self.path == "/policy/reload":
            pol = self.server.engine.reload_policy()
            self._send(200, {"ok": True, "policy": pol})
            return

        self._send(404, {"ok": False, "error": "not found"})

    def do_POST(self):
        # policy update (GUI)
        if self.path == "/policy":
            try:
                body = self._read_json()
            except ValueError as e:
                self._send(413, {"ok": False, "error": str(e)})
                return
            except Exception:
                self._send(400, {"ok": False, "error": "invalid json"})
                return

            patch = body.get("patch", body)  # allow either {"patch":{...}} or direct object
            ok, err, pol = self.server.engine.update_policy(patch if isinstance(patch, dict) else {})
            if ok:
                self._send(200, {"ok": True, "policy": pol})
            else:
                self._send(400, {"ok": False, "error": err})
            return

        # execute (existing)
        if self.path != "/execute":
            self._send(404, {"ok": False, "error": "not found"})
            return

        try:
            body = self._read_json()
        except ValueError as e:
            self._send(413, {"ok": False, "error": str(e)})
            return
        except Exception:
            self._send(400, {"ok": False, "error": "invalid json"})
            return

        action = body.get("action", "")
        params = body.get("params", {}) if isinstance(body.get("params", {}), dict) else {}
        consent = bool(body.get("consent", False))
        reason = body.get("reason", "")

        resp = self.server.engine.execute(action, params, consent, reason)

        # keep your behavior: always 200 with ok false/true in JSON
        self._send(200, resp)


# -----------------------------
# Main
# -----------------------------

def main():
    repo_root = abspath(os.path.join(os.path.dirname(__file__), ".."))
    policy_path = os.environ.get("BUDDY_POLICY_PATH", os.path.join(repo_root, "broker", "policy.json"))
    audit_path = os.environ.get("BUDDY_AUDIT_PATH", os.path.join(repo_root, "broker", "audit.log.jsonl"))
    host = os.environ.get("BUDDY_HOST", "127.0.0.1")
    port = int(os.environ.get("BUDDY_PORT", "8765"))

    engine = ActionsEngine(repo_root, policy_path, audit_path)

    httpd = ThreadingHTTPServer((host, port), Handler)
    httpd.engine = engine

    sys.stdout.write(f"buddy-actions listening on http://{host}:{port}\n")
    sys.stdout.write(f"policy: {policy_path}\n")
    sys.stdout.write(f"audit:  {audit_path}\n")
    sys.stdout.write(f"ollama: {engine.ollama_tags_url}\n")
    sys.stdout.write(f"shell:  {'ENABLED' if engine.enable_shell else 'disabled'}\n")
    sys.stdout.flush()

    httpd.serve_forever()


if __name__ == "__main__":
    main()

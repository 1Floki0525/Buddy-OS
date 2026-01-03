#!/usr/bin/env python3
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

def now_utc():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

def read_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, sort_keys=True)
        f.write("\n")
    os.replace(tmp, path)

def abspath(p):
    return os.path.abspath(os.path.expanduser(p))

def path_is_under(p, root):
    p = os.path.normpath(p)
    root = os.path.normpath(root)
    if p == root:
        return True
    return p.startswith(root + os.sep)

def redact_secrets(s):
    if not isinstance(s, str):
        return s
    s = re.sub(r"(ghp_[A-Za-z0-9]{20,})", "[REDACTED_GITHUB_TOKEN]", s)
    s = re.sub(r"(sk-[A-Za-z0-9]{20,})", "[REDACTED_OPENAI_KEY]", s)
    s = re.sub(r"(AIza[0-9A-Za-z\-_]{20,})", "[REDACTED_GOOGLE_KEY]", s)
    s = re.sub(r"([A-Za-z0-9_\-]{24,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,})", "[REDACTED_JWT]", s)
    return s

def default_policy(repo_root):
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
            "shell": "deny"
        },
        "re_auth_required": {
            "shell": True
        }
    }

class ActionsEngine:
    def __init__(self, repo_root, policy_path, audit_path):
        self.repo_root = repo_root
        self.policy_path = policy_path
        self.audit_path = audit_path
        self.policy = self.load_policy()

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

    def audit(self, entry):
        os.makedirs(os.path.dirname(self.audit_path), exist_ok=True)
        safe = {}
        for k, v in entry.items():
            if isinstance(v, str):
                safe[k] = redact_secrets(v)
            else:
                safe[k] = v
        safe["timestamp"] = now_utc()
        with open(self.audit_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(safe, ensure_ascii=False) + "\n")

    def check_path(self, target_path):
        p = abspath(target_path)
        allow_mode = self.policy.get("allow_mode", "allowlist")
        allowlist = [abspath(x) for x in self.policy.get("allowlist", [])]
        blacklist = [abspath(x) for x in self.policy.get("blacklist", [])]

        for b in blacklist:
            if path_is_under(p, b):
                return False, f"Path is blacklisted: {b}"

        if allow_mode == "allowlist":
            for a in allowlist:
                if path_is_under(p, a):
                    return True, ""
            return False, "Path not in allowlist"
        return True, ""

    def consent_rule(self, action):
        return self.policy.get("consent", {}).get(action, "ask")

    def require_reauth(self, action):
        return bool(self.policy.get("re_auth_required", {}).get(action, False))

    def exec_mkdir(self, params):
        path = params.get("path", "")
        if not path:
            return False, "missing path", None
        ok, msg = self.check_path(path)
        if not ok:
            return False, msg, None
        p = abspath(path)
        os.makedirs(p, exist_ok=True)
        return True, "", {"path": p}

    def exec_write_file(self, params):
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
            f.write(content)
        return True, "", {"path": p, "bytes": len(content.encode("utf-8"))}

    def exec_list_dir(self, params):
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

    def exec_open_url(self, params):
        url = params.get("url", "")
        if not url:
            return False, "missing url", None
        subprocess.Popen(["xdg-open", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True, "", {"url": url}

    def exec_launch_app(self, params):
        cmd = params.get("cmd", [])
        if not isinstance(cmd, list) or not cmd:
            return False, "missing cmd list", None
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True, "", {"cmd": cmd}

    def exec_shell(self, params):
        cmd = params.get("cmd", "")
        if not cmd:
            return False, "missing cmd", None
        return False, "shell disabled in this build (deny by default)", None

    def list_ollama_local_models(self):
        url = "http://localhost:11434/api/tags"
        try:
            req = Request(url, headers={"Accept": "application/json"})
            with urlopen(req, timeout=3) as r:
                data = json.loads(r.read().decode("utf-8", errors="replace"))
            models = []
            for m in data.get("models", []):
                name = m.get("name")
                if name:
                    models.append(name)
            return True, models, ""
        except (URLError, HTTPError, ValueError) as e:
            return False, [], str(e)

    def execute(self, action, params, consent, reason):
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
            "shell": self.exec_shell
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

class Handler(BaseHTTPRequestHandler):
    server_version = "buddy-actions/0.1"

    def _send(self, code, obj):
        data = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _read_json(self):
        n = int(self.headers.get("Content-Length", "0") or "0")
        raw = self.rfile.read(n) if n > 0 else b"{}"
        return json.loads(raw.decode("utf-8", errors="replace") or "{}")

    def do_GET(self):
        if self.path == "/health":
            self._send(200, {"ok": True, "service": "buddy-actions", "version": "0.1"})
            return
        if self.path == "/providers/ollama-local/models":
            ok, models, err = self.server.engine.list_ollama_local_models()
            if ok:
                self._send(200, {"ok": True, "provider": "ollama-local", "models": models})
            else:
                self._send(503, {"ok": False, "provider": "ollama-local", "error": err})
            return
        if self.path == "/policy/reload":
            pol = self.server.engine.reload_policy()
            self._send(200, {"ok": True, "policy": pol})
            return
        self._send(404, {"ok": False, "error": "not found"})

    def do_POST(self):
        if self.path != "/execute":
            self._send(404, {"ok": False, "error": "not found"})
            return
        try:
            body = self._read_json()
        except Exception:
            self._send(400, {"ok": False, "error": "invalid json"})
            return
        action = body.get("action", "")
        params = body.get("params", {}) if isinstance(body.get("params", {}), dict) else {}
        consent = bool(body.get("consent", False))
        reason = body.get("reason", "")
        resp = self.server.engine.execute(action, params, consent, reason)
        self._send(200, resp)

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
    sys.stdout.flush()
    httpd.serve_forever()

if __name__ == "__main__":
    main()

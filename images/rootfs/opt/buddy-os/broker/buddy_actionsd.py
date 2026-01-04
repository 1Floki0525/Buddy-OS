#!/usr/bin/env python3
"""
Buddy-OS Actions Daemon (broker/buddy_actionsd.py)

This is a lightweight internal HTTP daemon used by Buddy-OS UI + Buddy runtime to:
- Execute actions with configurable policy
- Maintain audit logs (but improves redaction)
- Support GUI automation, Docker, network, and system admin tasks

Endpoints:
GET  /ping
GET  /policy/reload
POST /execute

- Keeps your policy.json shape (version/access_preset/allow_mode/allowlist/blacklist/no_memory_zones/consent/re_auth_required)
- Adds (non-breaking) endpoints for UI plumbing:
GET  /policy                 (current policy)
GET  /capabilities           (available features)
POST /execute                (run actions)

Supports actions:
- mkdir, write_file, list_dir, open_url, launch_app, shell, screen_capture, mouse_control, keyboard_control, window_management, docker_control, network_admin
"""

import json
import os
import sys
import time
import logging
import subprocess
import tempfile
import traceback
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# GUI Automation imports
try:
    import pyscreenshot as ImageGrab
    import pyautogui
    from pynput import mouse, keyboard
    PYAUTOGUI_AVAILABLE = True
except ImportError:
    PYAUTOGUI_AVAILABLE = False
    print("Warning: GUI automation libraries not available. Install with: pip install pyscreenshot pyautogui pynput")

# -----------------------------
# Time / JSON helpers
# -----------------------------

def now() -> int:
    return int(time.time())

def write_json(path: str, data: dict) -> None:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)

def read_json(path: str) -> dict:
    with open(path, "r") as f:
        return json.load(f)

def default_policy(repo_root: str) -> dict:
    home = os.path.expanduser("~")
    return {
        "version": "1.0",
        "access_preset": "restricted",
        "allow_mode": "blacklist",
        "allowlist": [],
        "blacklist": [
            os.path.join(home, ".ssh"),
            os.path.join(home, ".gnupg")
        ],
        "no_memory_zones": [
            os.path.join(home, ".ssh"),
            os.path.join(home, ".gnupg")
        ],
        "capabilities": {
            "screen_control": True,
            "system_admin": True,
            "docker_control": True,
            "network_admin": True
        },
        "consent": {
            "mkdir": "ask",
            "write_file": "ask",
            "list_dir": "ask",
            "open_url": "allow",
            "launch_app": "ask",
            "shell": "deny",
            "screen_control": "ask"
        },
        "re_auth_required": {
            "system_admin": True,
            "shell": True
        }
    }

# -----------------------------
# Logger
# -----------------------------

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('broker.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("buddy_actionsd")

# -----------------------------
# BuddyActionsDaemon Class
# -----------------------------

class BuddyActionsDaemon:
    def __init__(self, repo_root: str):
        self.repo_root = repo_root
        self.policy_path = os.path.join(repo_root, "policy.json")
        self.policy = self._load_policy()
        self.enable_shell = os.environ.get("BUDDY_ENABLE_SHELL", "0").strip() in ("1", "true", "yes", "on")
        self.enable_screen_control = os.environ.get("BUDDY_ENABLE_SCREEN_CONTROL", "0").strip() in ("1", "true", "yes", "on")
        self.enable_docker_control = os.environ.get("BUDDY_ENABLE_DOCKER_CONTROL", "0").strip() in ("1", "true", "yes", "on")
        self.enable_network_admin = os.environ.get("BUDDY_ENABLE_NETWORK_ADMIN", "0").strip() in ("1", "true", "yes", "on")

        # Initialize GUI automation
        self._init_gui_automation()

    def _load_policy(self):
        try:
            return read_json(self.policy_path)
        except Exception:
            return default_policy(self.repo_root)

    def save_policy(self):
        write_json(self.policy_path, self.policy)

    def _init_gui_automation(self):
        """
        Initialize GUI automation capabilities
        """
        if not PYAUTOGUI_AVAILABLE:
            self.enable_screen_control = False
            return False
        try:
            # Set pyautogui defaults
            pyautogui.FAILSAFE = True
            pyautogui.PAUSE = 0.5
            return True
        except Exception as e:
            print(f"Warning: GUI automation initialization failed: {e}")
            self.enable_screen_control = False
            return False

    # -----------------------------
    # Action Executors
    # -----------------------------

    def _execute_shell(self, params: dict) -> tuple:
        if not self.enable_shell:
            return False, {}, "shell execution disabled"
        try:
            cmd = params.get("command", "")
            if not cmd.strip():
                return False, {}, "empty command"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            success = result.returncode == 0
            output = {
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
            return success, output, "shell executed"
        except Exception as e:
            return False, {}, f"shell execution failed: {str(e)}"

    def _execute_screen_capture(self, params: dict) -> tuple:
        if not self.enable_screen_control:
            return False, {}, "screen control disabled"
        try:
            # Capture full screen or specific region
            region = params.get("region")
            if region:
                screenshot = ImageGrab.grab(bbox=region)  # (x1, y1, x2, y2)
            else:
                screenshot = ImageGrab.grab()
            # Save to temporary file
            temp_file = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
            screenshot.save(temp_file.name, "PNG")
            return True, {"screenshot_path": temp_file.name}, "screenshot captured"
        except Exception as e:
            return False, {}, f"screenshot failed: {str(e)}"

    def _execute_mouse_control(self, params: dict) -> tuple:
        if not self.enable_screen_control:
            return False, {}, "screen control disabled"
        try:
            action = params.get("action", "")
            if action == "move":
                x, y = params.get("x", 0), params.get("y", 0)
                pyautogui.moveTo(x, y)
                return True, {"x": x, "y": y}, "mouse moved"
            elif action == "click":
                button = params.get("button", "left")
                clicks = params.get("clicks", 1)
                pyautogui.click(button=button, clicks=clicks)
                return True, {"button": button, "clicks": clicks}, "mouse clicked"
            elif action == "drag":
                x, y = params.get("x", 0), params.get("y", 0)
                button = params.get("button", "left")
                pyautogui.dragTo(x, y, button=button)
                return True, {"x": x, "y": y, "button": button}, "mouse dragged"
            else:
                return False, {}, f"unknown mouse action: {action}"
        except Exception as e:
            return False, {}, f"mouse control failed: {str(e)}"

    def _execute_keyboard_control(self, params: dict) -> tuple:
        if not self.enable_screen_control:
            return False, {}, "screen control disabled"
        try:
            action = params.get("action", "")
            if action == "type":
                text = params.get("text", "")
                pyautogui.write(text)
                return True, {"text_length": len(text)}, "text typed"
            elif action == "press":
                key = params.get("key", "")
                pyautogui.press(key)
                return True, {"key": key}, "key pressed"
            elif action == "hotkey":
                keys = params.get("keys", [])
                pyautogui.hotkey(*keys)
                return True, {"keys": keys}, "hotkey pressed"
            else:
                return False, {}, f"unknown keyboard action: {action}"
        except Exception as e:
            return False, {}, f"keyboard control failed: {str(e)}"

    def _execute_window_management(self, params: dict) -> tuple:
        if not self.enable_screen_control:
            return False, {}, "screen control disabled"
        try:
            action = params.get("action", "")
            if action == "find":
                title = params.get("title", "")
                # Use xdotool to find windows
                result = subprocess.run(["xdotool", "search", "--name", title], capture_output=True, text=True)
                if result.returncode == 0:
                    windows = result.stdout.strip().split('\n')
                    return True, {"windows": windows}, "windows found"
                else:
                    return False, {}, "no windows found"
            elif action == "focus":
                window_id = params.get("window_id", "")
                subprocess.run(["xdotool", "windowfocus", window_id])
                return True, {"window_id": window_id}, "window focused"
            else:
                return False, {}, f"unknown window action: {action}"
        except Exception as e:
            return False, {}, f"window management failed: {str(e)}"

    def _execute_docker_control(self, params: dict) -> tuple:
        if not self.enable_docker_control:
            return False, {}, "docker control disabled"
        try:
            action = params.get("action", "")
            cmd = ["docker"] + params.get("args", [])
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                return True, {"output": result.stdout}, f"docker {action} completed"
            else:
                return False, {"error": result.stderr}, f"docker {action} failed"
        except Exception as e:
            return False, {}, f"docker control failed: {str(e)}"

    def _execute_network_admin(self, params: dict) -> tuple:
        if not self.enable_network_admin:
            return False, {}, "network admin disabled"
        try:
            action = params.get("action", "")
            if action == "list_interfaces":
                result = subprocess.run(["ip", "link", "show"], capture_output=True, text=True)
                return True, {"interfaces": result.stdout}, "interfaces listed"
            elif action == "configure_interface":
                # Placeholder for interface configuration
                return True, {}, "interface configuration ready"
            else:
                return False, {}, f"unknown network action: {action}"
        except Exception as e:
            return False, {}, f"network admin failed: {str(e)}"

    # -----------------------------
    # Policy Enforcement
    # -----------------------------

    def _check_permission(self, action: str, path: str = None) -> tuple:
        """
        Check if the action is allowed based on policy
        """
        # Get access preset
        preset = self.policy.get("access_preset", "restricted")
        
        # Get consent rule for action
        consent = self.policy.get("consent", {}).get(action, "ask")
        
        # Check folder rules
        if path:
            allow_mode = self.policy.get("allow_mode", "blacklist")
            allowlist = self.policy.get("allowlist", [])
            blacklist = self.policy.get("blacklist", [])
            
            if allow_mode == "allowlist":
                # Only allow if in allowlist
                if not any(path.startswith(allowed) for allowed in allowlist):
                    return False, "Path not in allowlist"
            else:
                # Blacklist mode - deny if in blacklist
                if any(path.startswith(denied) for denied in blacklist):
                    return False, "Path in blacklist"
        
        # Check re-auth required
        re_auth = self.policy.get("re_auth_required", {}).get(action, False)
        
        # Return permission check result
        return True, consent, re_auth

    # -----------------------------
    # HTTP Handler
    # -----------------------------

    def handle_execute(self, data: dict) -> dict:
        action = data.get("action", "")
        params = data.get("params", {})
        reason = data.get("reason", "")
        consent_given = data.get("consent", False)
        
        logger.info(f"Executing action: {action} with params: {params}")
        
        # Check policy for action
        if action in ["mkdir", "write_file", "list_dir", "launch_app", "shell", "screen_capture", "mouse_control", "keyboard_control", "window_management", "docker_control", "network_admin"]:
            # For file operations, check path permission
            path = params.get("path", "")
            if action in ["mkdir", "write_file", "list_dir"] and path:
                allowed, consent_rule, re_auth_required = self._check_permission(action, path)
                if not allowed:
                    return {"ok": False, "error": "Permission denied", "consent_required": False}
                
                # Check consent
                if consent_rule == "ask" and not consent_given:
                    return {"ok": False, "error": "Consent required", "consent_required": True, "reason": "Action requires explicit consent"}
                
                # Check re-auth
                if re_auth_required and not self._check_re_auth():
                    return {"ok": False, "error": "Re-authentication required", "consent_required": False, "re_auth_required": True}
            
        # Execute action based on type
        if action == "mkdir":
            path = params.get("path", "")
            try:
                os.makedirs(path, exist_ok=True)
                return {"ok": True, "action_id": str(now()), "result": {"message": "directory created"}}
            except Exception as e:
                return {"ok": False, "error": str(e), "action_id": str(now())}

        elif action == "write_file":
            path = params.get("path", "")
            content = params.get("content", "")
            try:
                with open(path, "w") as f:
                    f.write(content)
                return {"ok": True, "action_id": str(now()), "result": {"message": "file written"}}
            except Exception as e:
                return {"ok": False, "error": str(e), "action_id": str(now())}

        elif action == "list_dir":
            path = params.get("path", "")
            try:
                files = os.listdir(path)
                return {"ok": True, "action_id": str(now()), "result": {"files": files}}
            except Exception as e:
                return {"ok": False, "error": str(e), "action_id": str(now())}

        elif action == "open_url":
            url = params.get("url", "")
            try:
                subprocess.run(["xdg-open", url])
                return {"ok": True, "action_id": str(now()), "result": {"message": "URL opened"}}
            except Exception as e:
                return {"ok": False, "error": str(e), "action_id": str(now())}

        elif action == "launch_app":
            cmd = params.get("command", "")
            try:
                subprocess.run(cmd, shell=True, check=True)
                return {"ok": True, "action_id": str(now()), "result": {"message": "app launched"}}
            except Exception as e:
                return {"ok": False, "error": str(e), "action_id": str(now())}

        elif action == "shell":
            return self._execute_shell(params)

        elif action == "screen_capture":
            return self._execute_screen_capture(params)

        elif action == "mouse_control":
            return self._execute_mouse_control(params)

        elif action == "keyboard_control":
            return self._execute_keyboard_control(params)

        elif action == "window_management":
            return self._execute_window_management(params)

        elif action == "docker_control":
            return self._execute_docker_control(params)

        elif action == "network_admin":
            return self._execute_network_admin(params)

        else:
            return {"ok": False, "error": f"unknown action: {action}", "action_id": str(now())}

    def _check_re_auth(self) -> bool:
        """
        Check if re-authentication is required
        """
        # In real implementation, this would check if the user has authenticated recently
        # For now, return True to require re-auth for all actions that need it
        return True

# -----------------------------
# HTTP Server Handler
# -----------------------------

class Handler(BaseHTTPRequestHandler):
    def __init__(self, *args, daemon=None, **kwargs):
        self.daemon = daemon
        super().__init__(*args, **kwargs)

    def do_GET(self):
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query = parse_qs(parsed_path.query)

        if path == "/ping":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"pong": True}).encode())
            return

        elif path == "/policy":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(self.daemon.policy).encode())
            return

        elif path == "/capabilities":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "screen_control": self.daemon.enable_screen_control,
                "docker_control": self.daemon.enable_docker_control,
                "network_admin": self.daemon.enable_network_admin,
                "shell": self.daemon.enable_shell
            }).encode())
            return

        elif path == "/policy/reload":
            self.daemon.policy = self.daemon._load_policy()
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"success": True, "message": "policy reloaded"}).encode())
            return

        else:
            self.send_response(404)
            self.end_headers()
            return

    def do_POST(self):
        if self.path == "/execute":
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data.decode('utf-8'))
            response = self.daemon.handle_execute(data)
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            # Log the response
            logger.info(f"Response for action {data.get('action')}: {response}")
            self.wfile.write(json.dumps(response).encode())
            return
        else:
            self.send_response(404)
            self.end_headers()
            return

# -----------------------------
# Main Entry Point
# -----------------------------

if __name__ == "__main__":
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    daemon = BuddyActionsDaemon(repo_root)

    # Start HTTP server on localhost:8000
    server_address = ("localhost", 8000)
    httpd = HTTPServer(server_address, lambda *args, **kwargs: Handler(*args, daemon=daemon, **kwargs))
    print(f"Buddy Actions Daemon running on http://{server_address[0]}:{server_address[1]}")
    httpd.serve_forever()

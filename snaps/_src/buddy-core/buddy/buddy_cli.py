#!/usr/bin/env python3
import json
import os
import sys
from urllib.request import Request, urlopen

def post(url, obj):
    data = json.dumps(obj).encode("utf-8")
    req = Request(url, data=data, headers={"Content-Type": "application/json"})
    with urlopen(req, timeout=10) as r:
        return json.loads(r.read().decode("utf-8", errors="replace"))

def get(url):
    with urlopen(url, timeout=10) as r:
        return json.loads(r.read().decode("utf-8", errors="replace"))

def main():
    base = os.environ.get("BUDDY_BASE", "http://127.0.0.1:8765")
    if len(sys.argv) < 2:
        print("usage:")
        print("  buddy_cli.py health")
        print("  buddy_cli.py ollama-models")
        print("  buddy_cli.py mkdir <path> [--yes]")
        print("  buddy_cli.py write <path> <content_file> [--yes]")
        print("  buddy_cli.py ls <path>")
        print("  buddy_cli.py open <url>")
        print("  buddy_cli.py app <cmd...> [--yes]")
        sys.exit(2)

    cmd = sys.argv[1]
    yes = "--yes" in sys.argv
    argv = [a for a in sys.argv[2:] if a != "--yes"]

    if cmd == "health":
        print(json.dumps(get(base + "/health"), indent=2))
        return

    if cmd == "ollama-models":
        print(json.dumps(get(base + "/providers/ollama-local/models"), indent=2))
        return

    if cmd == "mkdir":
        if len(argv) < 1:
            sys.exit(2)
        resp = post(base + "/execute", {"action": "mkdir", "params": {"path": argv[0]}, "consent": yes, "reason": "create folder"})
        print(json.dumps(resp, indent=2))
        return

    if cmd == "write":
        if len(argv) < 2:
            sys.exit(2)
        path = argv[0]
        content_file = argv[1]
        with open(content_file, "r", encoding="utf-8") as f:
            content = f.read()
        resp = post(base + "/execute", {"action": "write_file", "params": {"path": path, "content": content}, "consent": yes, "reason": "write file"})
        print(json.dumps(resp, indent=2))
        return

    if cmd == "ls":
        if len(argv) < 1:
            sys.exit(2)
        resp = post(base + "/execute", {"action": "list_dir", "params": {"path": argv[0]}, "consent": True, "reason": "list directory"})
        print(json.dumps(resp, indent=2))
        return

    if cmd == "open":
        if len(argv) < 1:
            sys.exit(2)
        resp = post(base + "/execute", {"action": "open_url", "params": {"url": argv[0]}, "consent": True, "reason": "open url"})
        print(json.dumps(resp, indent=2))
        return

    if cmd == "app":
        if len(argv) < 1:
            sys.exit(2)
        resp = post(base + "/execute", {"action": "launch_app", "params": {"cmd": argv}, "consent": yes, "reason": "launch app"})
        print(json.dumps(resp, indent=2))
        return

    print("unknown command")
    sys.exit(2)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import json, os, sys

def load(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def save(path, obj):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2, sort_keys=True)
        f.write("\n")
    os.replace(tmp, path)

def uniq(seq):
    out = []
    seen = set()
    for x in seq:
        if x not in seen:
            out.append(x)
            seen.add(x)
    return out

def abspath(p):
    return os.path.abspath(os.path.expanduser(p))

def main():
    repo_root = abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    policy_path = os.environ.get("BUDDY_POLICY_PATH", os.path.join(repo_root, "broker", "policy.json"))
    if not os.path.exists(policy_path):
        print("missing policy.json", file=sys.stderr)
        sys.exit(1)

    if len(sys.argv) < 2:
        print("usage: policy_edit.py <cmd> [...]", file=sys.stderr)
        sys.exit(2)

    p = load(policy_path)
    cmd = sys.argv[1]

    if cmd == "set-preset":
        if len(sys.argv) != 3:
            sys.exit(2)
        p["access_preset"] = sys.argv[2]

    elif cmd == "set-allow-mode":
        if len(sys.argv) != 3:
            sys.exit(2)
        p["allow_mode"] = sys.argv[2]

    elif cmd == "add-allow":
        if len(sys.argv) != 3:
            sys.exit(2)
        p["allowlist"] = uniq([abspath(x) for x in (p.get("allowlist") or [])] + [abspath(sys.argv[2])])

    elif cmd == "add-black":
        if len(sys.argv) != 3:
            sys.exit(2)
        p["blacklist"] = uniq([abspath(x) for x in (p.get("blacklist") or [])] + [abspath(sys.argv[2])])

    elif cmd == "add-nomem":
        if len(sys.argv) != 3:
            sys.exit(2)
        p["no_memory_zones"] = uniq([abspath(x) for x in (p.get("no_memory_zones") or [])] + [abspath(sys.argv[2])])

    elif cmd == "set-consent":
        if len(sys.argv) != 4:
            sys.exit(2)
        action = sys.argv[2]
        rule = sys.argv[3]
        c = p.get("consent") or {}
        c[action] = rule
        p["consent"] = c

    elif cmd == "set-reauth":
        if len(sys.argv) != 4:
            sys.exit(2)
        action = sys.argv[2]
        val = sys.argv[3].lower() in ("1", "true", "yes", "on")
        r = p.get("re_auth_required") or {}
        r[action] = val
        p["re_auth_required"] = r

    elif cmd == "show":
        print(json.dumps(p, indent=2, sort_keys=True))
        return

    else:
        print("unknown cmd", file=sys.stderr)
        sys.exit(2)

    save(policy_path, p)

if __name__ == "__main__":
    main()

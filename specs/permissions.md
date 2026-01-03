# Buddy-OS Permissions Spec

This document defines the permission system for Buddy-OS.

## Principles
- Buddy starts **Restricted by default**
- Permissions are **explicit, user-controlled, and reversible**
- High-risk actions require **consent** and sometimes **re-auth**
- Folder rules are enforced before any action executes
- No-memory zones must prevent retention in long-term memory

## Access Presets

### 1) Restricted (Default)
Allowed:
- Chat + explain + plan
- Create/read/write files ONLY in Buddy workspace:
  - `~/Buddy` or `~/Documents/Buddy` (final path decided later)
- Open URLs in the browser (no automation)
- Launch user apps (optional toggle; default OFF)

Requires consent:
- Any file access outside workspace
- Any command execution
- Any browser automation
- Any install/update actions
- Any email send or account access

### 2) Helpful
Allowed:
- Read/write in allowlisted folders
- Launch apps
- Open URLs
- Limited browser automation (explicit per-run consent by default)

Requires consent:
- Writing outside allowlist
- Deleting files outside workspace
- Running scripts/commands that modify system state
- Any credentials access
- Any email send

### 3) Power User
Allowed:
- Broad access to user home except blacklist
- Browser automation (can be “Ask once per session”)
- Run developer workflows inside a controlled environment

Requires consent:
- Deletes outside Trash
- Access to credentials store
- System-level changes

### 4) Admin (Danger Zone)
Allowed:
- Everything a user can do, including privileged actions,
  but still gated by consent + re-auth rules.

Requires re-auth:
- Installing/removing software
- Changing network/firewall/security settings
- Modifying system services
- Accessing sensitive folders (if not explicitly allowlisted)
- Exporting private data

## Consent Levels (Per Action Category)
Each category supports:
- Deny
- Ask every time
- Ask once per session
- Allow silently (recommended only for low-risk actions)

## Action Categories
1. Read files
2. Write files
3. Delete files
4. Run commands / scripts
5. Launch apps
6. Browser automation
7. Network requests (download/upload/API)
8. Email send / calendar actions
9. Credentials access
10. System/admin operations

## Folder Controls

### Modes
- Allowlist mode:
  Buddy can access ONLY listed folders (plus Buddy workspace)
- Blacklist mode:
  Buddy can access home EXCEPT listed folders
- Mixed mode (future):
  allowlist for write + broader read

### No-Memory Zones
- Buddy may access files in these folders to complete a task
- Buddy must NOT:
  - store summaries to long-term memory
  - store embeddings/vectors of content
  - quote sensitive content into logs
- Logs must redact secrets automatically

## Enforcement Order (Must Happen Every Time)
1. Identify intended action category
2. Check access preset + category rule
3. Check folder allow/deny/no-memory constraints
4. If required: ask consent / require re-auth
5. Execute action
6. Write audit log entry (with redaction)
7. Update memory only if allowed by rules

## Audit Log (Minimum Fields)
- timestamp (UTC)
- user
- provider + model (if applicable)
- requested intent
- actions executed (typed)
- resources touched (paths/URLs/app names; redacted if needed)
- consent result (asked/approved/denied; re-auth yes/no)
- outcome (success/failure + error)


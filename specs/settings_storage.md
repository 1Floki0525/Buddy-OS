# Buddy-OS Settings Storage Spec

End-user rule: settings are GUI-only.

## What We Store
A) Preferences and policy (non-secret)
- Provider selection
- Model selection
- Permission preset + consent matrix
- Folder allowlist/blacklist
- No-memory zones
- UI preferences

B) Secrets
- Provider API keys
- OAuth tokens

## Where We Store It

### Non-secret settings
Store in a standard desktop settings backend so UI is instant and reliable.
Implementation can be:
- gsettings/dconf (preferred for desktop integration)
or
- local sqlite database in Buddy user data

### Secrets
Store in OS secure storage (Secret Service / keyring style).
Requirements:
- encrypted at rest
- only accessible to Buddy components that need it
- GUI can set/update/remove secrets without showing them

## Export / Diagnostics
A user may export diagnostics from Buddy AI Settings:
- must redact secrets
- must redact contents from no-memory zones
- must include:
  - current provider/model (non-secret)
  - permission dial + consent matrix (non-secret)
  - last N audit entries (redacted)


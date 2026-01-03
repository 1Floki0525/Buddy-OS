# Buddy AI Settings (UI + Behavior Spec)

## Location
OS Settings → **Buddy AI**

## Sections

### 1) Provider & Model
- Provider dropdown:
  - GPT-Neo (Default)
  - Ollama Local
  - Ollama Cloud
  - OpenAI
  - Google (Gemini)
  - xAI (Grok)
- Model dropdown:
  - Auto-populate based on provider
  - Refresh button
- Connection status:
  - Connected / Not Connected / Error
- Buttons:
  - Test connection
  - Connect (provider-specific)
  - Disconnect

### 2) Consent Rules
A matrix with categories:
- Read files
- Write files
- Delete files
- Run commands / scripts
- Launch apps
- Browser automation
- Network requests (download/upload)
- Email send / calendar actions
- Credentials access
- System/admin operations

Each category has:
- Always ask
- Ask once per session
- Allow in allowlisted scope
- Allow silently (only for low-risk categories)

### 3) Folder Access Controls
Three modes:
- Allowlist: Buddy can touch ONLY these folders
- Blacklist: Buddy can touch home EXCEPT these folders
- Mixed: allowlist for write + broader read (optional future)

Plus:
- No-memory zones:
  - Buddy may access for tasks
  - Buddy must not store embeddings/summaries/quotes to long-term memory
  - Buddy must redact secrets from logs

### 4) Memory & Privacy
- Persistent memory:
  - On/Off
  - Clear memory
  - Export memory
- Audit log:
  - On/Off (default ON)
  - Verbosity level
  - Export audit log

### 5) Advanced
- Custom base URLs per provider (for self-hosting)
- Rate limits / cost caps (for cloud providers)
- Offline-only mode toggle

## UX Requirements
- Any risky action must follow:
  Plan → Preview → Execute → Summary + Audit Log

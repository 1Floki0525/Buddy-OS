# Buddy-OS UI Spec

Buddy-OS should feel like Pop!_OS: rounded, modern, clean, and fast.
Buddy must be usable with or without a microphone.

## Visual Language
- Rounded corners across surfaces (panels, cards, menus, dialogs)
- Soft shadows (subtle depth; no heavy blur by default)
- Clean spacing + readable typography
- Optional animation, short + efficient (toggleable)
- Low idle resource usage is a first-class requirement

## Desktop Surface Components

### 1) Buddy Bar (Bottom Widget)
Always visible on the desktop.

Contains:
- Status orb: Idle / Listening / Thinking / Needs Approval / Running
- Text input (always enabled)
- Optional mic button (only shown if enabled)
- Expand arrow (opens the Buddy Drawer)

Behavior:
- Enter submits
- Shift+Enter new line
- Esc closes drawer (if open)
- Hotkey opens/closes drawer (final hotkey decided later)

### 2) Buddy Drawer (Expandable Chat Panel)
Slides up from bottom when expanded.

Tabs/sections:
- Chat
- Plan (what Buddy intends to do)
- Approvals (pending confirmations + re-auth prompts)
- Activity (audit view with timestamps + outcomes)

Plan → Preview → Execute:
- For non-trivial actions Buddy must present:
  1) Plan (steps)
  2) Preview (diffs, exact email body, file changes, commands)
  3) Execute (live progress)
  4) Summary (what changed) + log entry

### 3) Notifications
- Non-intrusive toast notifications for:
  - completed tasks
  - errors
  - approvals required
- Clicking a notification opens the drawer at the relevant section

### 4) Buddy AI Settings (OS Settings Integration)
OS Settings includes a dedicated section: Buddy AI
No terminal. No text editing. All user configuration is GUI-only.

Sections:

A) Provider & Model
- Provider dropdown:
  - GPT-Neo (Local default baseline)
  - Ollama (Local)
  - Ollama (Cloud)
  - OpenAI
  - Google (Gemini)
  - xAI (Grok)
- Model dropdown:
  - Populated dynamically based on provider
  - Refresh button
- Status:
  - Connected / Not connected / Error
- Buttons:
  - Connect
  - Disconnect
  - Test connection

B) Auth (Per Provider)
- API key entry:
  - masked input
  - paste + verify
- OAuth/login flow (where applicable):
  - Connect opens browser to provider login
  - returns to Buddy-OS
- Secrets must be stored in OS secure storage (not plaintext files)

C) Permissions
- Presets:
  - Restricted (default)
  - Helpful
  - Power User
  - Admin
- Consent matrix per category:
  - Deny
  - Ask every time
  - Ask once per session
  - Allow (where safe)
- Re-auth controls:
  - require PIN/password for high-risk operations

D) Folder Access
- Allowlist mode (only these folders)
- Blacklist mode (everything except these folders)
- No-memory zones:
  - Buddy can act there but cannot retain content in long-term memory

E) Memory & Privacy
- Persistent memory toggle
- Clear memory
- Export diagnostics (redacted)
- Audit log toggle (default ON)
- Export audit log (redacted)

## Accessibility
- Full keyboard navigation for Buddy Bar and Drawer
- High-contrast mode compatible
- Large text scaling compatible

## Performance Requirements
- Buddy Bar idle should be near-zero CPU usage
- Drawer rendering should be lazy (only render when opened)
- Avoid heavy blur effects by default

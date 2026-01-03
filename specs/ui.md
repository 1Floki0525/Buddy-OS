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

Key rules:
- Default local model: `ollama-local / qwen3-vl:2b` (works offline)
- Only two active models at a time:
  - Desktop Agent
  - Dev Agent

## Accessibility
- Full keyboard navigation for Buddy Bar and Drawer
- High-contrast mode compatible
- Large text scaling compatible

## Performance Requirements
- Buddy Bar idle should be near-zero CPU usage
- Drawer rendering should be lazy (only render when opened)
- Avoid heavy blur effects by default

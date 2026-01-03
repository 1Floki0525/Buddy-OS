# Buddy-OS — ABOUT

Buddy-OS is a fully AI-assisted operating system built on **Ubuntu Core 24 (Ubuntu 24.04 LTS foundation)** with a **Pop!_OS-like look/feel** (rounded, modern, efficient) and a first-class, persistent AI assistant named **Buddy**.

Buddy-OS boots into a desktop experience where Buddy is always available via a bottom-screen widget (the “Buddy Bar”), with an expand arrow for a full chat panel. Voice is optional; text-first is always supported.

This file is the canonical spec anchor for the project.
If a new chat is started, this file is the source of truth.

---

## Core Goals

1. **Immutable + Secure by Default**
   - Ubuntu Core as the backbone for a locked-down, resilient base.
   - Buddy starts restricted by default.

2. **One Persistent Agent**
   - Buddy is a single agent with persistent memory (user-controlled).
   - Buddy can perform tasks across the system like a human user would.

3. **Permission Dial**
   - OS Settings includes a dedicated **“Buddy AI”** tab.
   - The user controls what Buddy can do:
     - What Buddy can do without explicit consent
     - What requires consent each time
     - What requires re-auth (PIN/password)
   - Folder-level controls:
     - Allowlist: Buddy can access ONLY selected folders
     - Blacklist: Buddy can access home EXCEPT selected folders
     - No-memory zones: Buddy can access but must NOT store/retain/summarize contents

4. **Pop!_OS-like UX Without Bloat**
   - Rounded UI, clean widgets, smooth but light animations.
   - Minimal idle CPU/RAM usage; avoid heavy background services.

5. **Model Strategy**
   - Offline-first default: **Ollama Local (seeded) / qwen3-vl:2b** (available out of the box).
   - Buddy uses **exactly two active models**:
     - **Desktop Agent** (everyday OS tasks)
     - **Dev Agent** (coding/dev tasks)
   - Optional integrations (user-configured in Settings):
     - Ollama Cloud
     - OpenAI
     - Gemini
     - Claude
     - Grok
   - Security model never changes with model choice: permissions are enforced by Buddy-OS.

   **Distribution rule:** large model seed artifacts must never be committed to git.
   - Repo stores only manifests + sha256.
   - Seed tarballs are hosted externally and fetched during build.

6. **Final Deliverable**
   - A **Ventoy-bootable ISO** for installation.
   - ISO installs Buddy-OS reliably on target hardware.

---

## System UX Requirements

### Buddy Bar (bottom widget)
- Always visible on the desktop.
- Contains:
  - Buddy status indicator (Idle / Listening / Thinking / Needs Approval / Running Task)
  - Text input (always)
  - Optional microphone button (if hardware exists)
  - Expand arrow (opens full chat drawer)

### Expandable Chat Drawer
- Shows:
  - Conversation thread
  - “Plan → Preview → Execute” workflow UI
  - Approvals queue (pending confirmations)
  - Activity/Audit log (what Buddy did, when, and why)

### OS Settings Integration
- Add a Settings section: **Buddy AI**
  - Access preset (Restricted / Helpful / Power User / Admin)
  - Consent matrix (per category)
  - Folder allowlist/blacklist/no-memory zones
  - Integrations + auth (providers, logins, keys)
  - Audit controls (log verbosity, export)

---

## Trust, Safety, and Control (Non-Negotiable)

Buddy-OS must be powerful without being sneaky.

### Action Transparency
- For non-trivial tasks Buddy must:
  1) Propose a plan
  2) Show a preview (diffs, exact email text, commands, etc.)
  3) Execute with live progress
  4) Summarize results and log changes

### Audit Log
- Buddy-OS maintains an immutable audit trail:
  - timestamp, intent, actions taken, results, failures
  - stored locally in Buddy-managed data storage

### Memory Boundaries
- “No-memory zones” are enforced:
  - never store contents
  - never embed contents
  - never summarize contents into long-term memory

---

## Technical Architecture (High-Level)

Buddy behaves as ONE agent, but internally Buddy-OS separates “thinking” from “privileged doing” to stay safe and stable.

- **Buddy Core**
  - Chat UI + planner + memory + skill routing

- **Action Execution Layer**
  - Performs file ops, app launches, browser automation, system changes
  - Enforces:
    - permission dial
    - folder allow/deny/no-memory rules
    - consent + re-auth rules
    - logging

- **Desktop Shell Integration**
  - Buddy Bar + drawer integrated into the desktop UX

---

## Repository Layout (Workspace)

- `docs/`      : project docs, guides, diagrams
- `specs/`     : formal specs (permissions, UI, installer, memory)
- `ui/`        : Buddy Bar + drawer UI code
- `buddy/`     : agent core, planner, memory, model router
- `broker/`    : execution layer (actions, consent gates, logging)
- `snaps/`     : snap packaging definitions for Buddy-OS components
- `build/`     : build outputs (images, ISO artifacts, logs)
- `scripts/`   : build scripts, tooling, CI helpers
- `assets/`    : icons, themes, wallpapers, sound
- `notes/`     : scratch notes / decisions / meeting logs
- `images/`    : screenshots, mockups

---

## Development Workflow Rules (for Chat Continuity)

- All instructions exchanged should be reproducible using:
  - bash scripts and/or nano-created files
- Prefer scripts that:
  - are idempotent (safe to re-run)
  - log what they do
  - avoid assumptions about external state

This ABOUT.md is the anchor document.
If future chats drift, return to this file and treat it as the spec baseline.

---

## Next Steps (Immediate)

1. Create `specs/permissions.md`
   - Define access presets + consent matrix + folder rules

2. Create `specs/ui.md`
   - Define Buddy Bar layout + drawer behavior + Settings tab mock spec

3. Create `specs/build.md`
   - Define how we build Ubuntu Core-based image and package a Ventoy-bootable ISO installer

4. Create `notes/DECISIONS.md`
   - Track key choices so we don’t lose direction across chats

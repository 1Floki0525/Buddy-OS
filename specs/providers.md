# Buddy-OS Providers & Auth Spec

End-user rule: all provider setup is done in GUI under:
OS Settings → Buddy AI

No terminal. No config-file editing for end users.

## Core Rules

### Offline-first default
Buddy-OS must work immediately after install with a bundled local model:
- **Default bundled model:** `ollama-local / qwen3-vl:2b` (seeded into the Ollama local store)

Users may keep the default forever without adding provider keys or logins.

### Only 2 active models at a time
Buddy uses exactly:
- **Desktop Agent model** (everyday OS tasks)
- **Dev Agent model** (coding/dev tasks)

More models can be available, but only these two are “active”.

## Provider List
- Ollama (Local)
- Ollama (Cloud)
- OpenAI
- Google (Gemini)
- Anthropic (Claude)
- xAI (Grok)

## UI Requirements (Provider & Model)
Each provider has its own section card in the Providers tab:

- Enable checkbox (provider on/off)
- Status indicator (Connected / Not connected / Error)
- Connect/Disconnect controls:
  - API key entry (masked) + Verify
  - OAuth/browser login where applicable
- Model dropdown (provider-specific; disabled until connected)
- Refresh Models button
- Test Connection button (optional but recommended)

## Model Listing Rules

### Ollama Local
- If Ollama is reachable at `http://127.0.0.1:11434`:
  - list models using `GET /api/tags`
- Bundled seed model `qwen3-vl:2b` must appear by default.

### Ollama Cloud
- When connected, list models via Ollama Cloud API (auth required).
- If not connected:
  - show Connect button and disable cloud model dropdown.
- Optional behavior (only if connected + permitted):
  - On first coding request, Buddy may prompt to pull/select a recommended coder model.

### OpenAI / Gemini / Claude / Grok
- When connected:
  - list models via provider API if supported.
- If listing is not available:
  - allow manual model entry as fallback (GUI field).

## Auth Rules (GUI Only)

### API Key (Common Path)
- Masked field (••••••)
- Paste key + Verify
- Disconnect removes key from secure storage.

### Browser Login Flow (OAuth-Style)
- Connect opens provider login in the browser
- On success, Buddy-OS stores token securely
- Disconnect revokes/removes token locally.

## Storage Rules
- Non-secret settings go in normal settings storage.
- Secrets (API keys/tokens) must go in OS secure storage and never in repo files.

## Distribution Rule (Important)
Large seed artifacts must never be committed to git.
- Repo stores: manifest + sha256
- Seed tarballs are hosted externally (Google Drive) and fetched during build.

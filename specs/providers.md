# Buddy-OS Providers & Auth (Spec)

This document defines how Buddy-OS supports multiple model providers while keeping:
- **One Buddy agent** (single identity + memory)
- **A stable security model** (permissions do NOT depend on provider)
- **User-controlled auth + privacy**

## Provider Dropdown (UI Requirement)

Buddy AI Settings must include:

- Provider:
  - GPT-Neo (local baseline default)
  - Ollama (Local)
  - Ollama (Cloud)
  - OpenAI
  - Google (Gemini)
  - xAI (Grok)

- Model:
  - Populated dynamically from the chosen provider
  - “Refresh models” button
  - “Test connection” button

- Auth:
  - Provider-specific “Connect” flow
  - Auth status indicator (Connected / Not Connected)
  - “Disconnect” option

---

## Ollama (Local)

### Auth
- None required for localhost usage.

### Base URL
- `http://localhost:11434/api`

### Model list
- `GET /api/tags` → populate model dropdown.

### Notes
- Must support users who already pulled models (`ollama pull ...`).
- If the Ollama daemon isn’t running, Buddy must show a clear error and a “Start Ollama” suggestion.

---

## Ollama (Cloud)

Buddy-OS must support TWO ways to authenticate:

### A) Sign-in flow (human-friendly)
- Provide a “Sign in to Ollama Cloud” button.
- Implementation calls the CLI:
  - `ollama signin`
- CLI triggers the web-based account sign-in.

### B) API key (programmatic / headless friendly)
- Provide an “API Key” field (stored in OS vault, not in plaintext config).
- Set environment variable at runtime:
  - `OLLAMA_API_KEY=...`
- Cloud acts as a remote Ollama host.

### Base URL
- `https://ollama.com/api`

### Model list
- `GET https://ollama.com/api/tags`

---

## OpenAI

### Auth
- API key (Bearer token).
- Keys MUST be stored in a local OS vault (never written into repo files).

### Model list
- Populated by calling the OpenAI models endpoint (implementation detail).

---

## Google (Gemini)

### Auth
- API key (easiest path)
- OAuth (optional path for stricter access control)

### Model list
- Populated by provider API.

---

## xAI (Grok)

### Auth
- API key.
- Stored in local OS vault.

### Model list
- Populated by provider API.

---

## Storage Rules (Non-Negotiable)

- Provider secrets are stored in Buddy-OS secure storage (vault).
- Repo config files may contain:
  - selected provider
  - selected model
  - base URLs
  - feature toggles
- Repo config files must NOT contain:
  - API keys
  - OAuth refresh tokens
  - session cookies

---

## Required Provider Abstraction (Internal)

Buddy Core calls a single interface:

- `list_models(provider) -> [models...]`
- `chat(provider, model, messages, tools) -> response`
- `healthcheck(provider) -> ok/error`
- `connect(provider, method) -> status`
- `disconnect(provider) -> status`

Provider selection must never bypass:
- consent rules
- folder allow/deny rules
- no-memory zones
- audit log requirements

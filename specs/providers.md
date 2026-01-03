# Buddy-OS Providers & Auth Spec

End-user rule: all provider setup is done in GUI under:
OS Settings → Buddy AI

No terminal, no config-file editing for users.

## Provider List
- GPT-Neo (Local default baseline)
- Ollama (Local)
- Ollama (Cloud)
- OpenAI
- Google (Gemini)
- xAI (Grok)

## UI Requirements (Provider & Model)
- Provider dropdown
- Model dropdown (populated dynamically)
- Refresh Models button
- Test Connection button
- Connect / Disconnect controls
- Status indicator (Connected / Not connected / Error)

## Model Listing Rules

### Ollama Local
- If Ollama is reachable at `http://localhost:11434`:
  - list models using `GET /api/tags`
- Model dropdown must reflect what the user already pulled locally.

### Ollama Cloud
- When connected:
  - list models using `GET https://ollama.com/api/tags`
- If not connected:
  - show Connect button and disable cloud model dropdown.

### OpenAI / Gemini / Grok
- When connected:
  - list models via provider API.
- If listing is not available for a provider:
  - allow manual model entry as a fallback (GUI field).

## Auth Rules (GUI Only)

### API Key (Common Path)
- Masked field (••••••)
- Paste key + Verify
- Disconnect removes key from secure storage.

### Browser Login Flow (OAuth-Style)
- Connect opens a provider login page in the browser
- On success, Buddy-OS receives token and stores it securely
- Disconnect revokes/removes token locally.

### Ollama Cloud Connect
Buddy AI Settings must support:
- Web sign-in flow (Connect opens sign-in)
- API key entry (optional alternative)

## Storage Rules

### Non-secret settings (OK to store in normal settings DB)
- selected provider
- selected model
- provider base URLs (if user overrides)
- feature toggles (offline-only, cost caps)
- permission dial + consent matrix
- folder allow/deny/no-memory lists

### Secrets (MUST be stored in OS secure storage)
- API keys
- OAuth access/refresh tokens
- session credentials

Secrets must never be written into repo files.

## Provider Switching Behavior
- Switching provider must not change security model
- Switching provider must not bypass:
  - consent prompts
  - folder restrictions
  - no-memory zones
  - audit logging

## Offline Behavior
- GPT-Neo local baseline must work without internet.
- Ollama Local works without internet if models are already present.
- Cloud providers must show clear offline/connection errors.


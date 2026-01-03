# Buddy Config

- `providers.example.json` is safe to commit (NO secrets).
- Real secrets (API keys, OAuth tokens) must live in the Buddy-OS vault (implementation later).

Planned files (not committed):
- `providers.json` (local machine settings, no secrets)
- `secrets.json` (NEVER plaintext; will be replaced by vault backend)

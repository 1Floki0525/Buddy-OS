# Buddy-OS Vault Spec (Secrets)

Goal: store provider credentials securely and keep them out of git and plaintext.

## Stored Items
- OpenAI API key
- Gemini API key or OAuth tokens
- Grok API key
- Ollama Cloud token or API key
- Future: email credentials/tokens

## Rules
- Never write secrets into repo files.
- Never print secrets to logs.
- UI displays only masked values.
- Disconnect removes local secrets.

## Access Control
- Buddy UI can request vault changes (set/remove)
- Buddy runtime can request vault reads only when needed to run a provider call
- Audit log must record that a secret was used, without revealing it

## Redaction
- Any text that matches known secret patterns must be redacted from:
  - audit logs
  - diagnostics exports
  - memory storage


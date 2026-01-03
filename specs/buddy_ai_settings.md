# Buddy AI Settings (UI + Behavior Spec)

## Location
OS Settings → Buddy AI

## Core Concept
Buddy-OS supports multiple providers, but Buddy only runs **two active models**:
- Desktop Agent: everyday OS tasks
- Dev Agent: coding/dev tasks

Default out-of-box:
- Desktop Agent = `ollama-local / qwen3-vl:2b`
- Dev Agent = `ollama-local / qwen3-vl:2b` (until user chooses otherwise)

Users can keep defaults forever with no logins.

## Providers Tab
Each provider has its own section:
- Enable checkbox
- Status pill: Connected / Not connected / Error
- Auth controls:
  - API key + Verify OR
  - Login button (browser OAuth) where applicable
- Model dropdown (provider-specific; disabled until connected)
- Refresh models

Providers:
- Ollama Local (includes bundled seed model `qwen3-vl:2b`)
- Ollama Cloud
- OpenAI
- Gemini
- Claude
- Grok

## Active Models Tab / Section
Two selectors:
- Desktop Agent (provider + model)
- Dev Agent (provider + model)

Rules:
- Exactly 2 active selections total (one for each agent).
- Switching models/providers never bypasses permissions/consent/audit.

## Consent Rules
High-risk actions must follow:
Plan → Preview → Execute → Summary + Audit Log

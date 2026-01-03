# Buddy-OS Decisions Log

## 2026-01-03
- Install UX requirement: install like a normal Ubuntu Desktop distro:
  - live ISO boots to desktop
  - offline install works
  - optional internet during install for updates and third-party drivers
  - uses Ubuntu Desktop Installer (Flutter/Subiquity)

- Base image decision:
  - Use **Ubuntu Desktop 24.04 ISO remix** as the installer backbone (not Ubuntu Core).

- Desktop UX decision:
  - Ship **Pop!_OS-style COSMIC desktop** on top of Ubuntu 24.04:
    - COSMIC session preinstalled
    - COSMIC set as default session after install (Phase A)
    - later: COSMIC also used in the live session (Phase B)

- Buddy model defaults:
  - Default offline baseline: Ollama Local (seeded) / qwen3-vl:2b
  - Two active models only:
    - Desktop Agent
    - Dev Agent

- Providers supported in UI:
  - Ollama Local / Ollama Cloud / OpenAI / Gemini / Claude / Grok

- Large model seed artifacts:
  - Never committed to git
  - Hosted externally and fetched during build

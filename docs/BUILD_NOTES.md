# Buddy-OS Build Notes (Living Checklist)

This file tracks build requirements and progress for Buddy-OS. It is a concise
guide to ensure all specs are implemented in the OS image.

## Platform & Installer
- Base: Ubuntu Core 24.04.3 (classic mode enabled).
- Desktop: COSMIC (System76/Pop!_OS repositories).
- Installer: Ubiquity desktop flow (offline + updates + third‑party drivers).
- Boot: GRUB/GRUB2 BIOS + UEFI hybrid ISO.
- Package managers: snapd, APT, Flatpak out‑of‑box.

## Branding & UX
- Plymouth splash uses `build/Buddy-OS-loadingscreen.png` with animated
  progress bar + shimmer.
- Wallpaper uses `assets/nebula.jpg` when present.
- Distro name/identifiers updated to “Buddy‑OS”.
- Buddy AI settings icon uses `assets/icons/buddy-ai.png`.

## AI Defaults & Providers
- Default bundled model: `ollama-local / qwen3-vl:2b`.
- Exactly two active models:
  - Desktop Agent
  - Dev Agent
- Providers supported: Ollama Local/Cloud, OpenAI, Gemini, Claude, Grok.
- GUI-only provider setup in OS Settings → Buddy AI.

## Permission & Safety
- Default preset: Restricted.
- Consent matrix enforced per action category.
- Folder allowlist/blacklist + no‑memory zones enforced before execution.
- Non‑trivial actions require Plan → Preview → Execute → Summary + Audit.
- Audit log is redacted; secrets never appear in logs.

## Storage
- Non‑secret settings: gsettings/dconf or local DB.
- Secrets: OS secure storage (keyring/Secret Service).

## Services & UI
- `buddy-actionsd` enabled at boot.
- Always‑on voice service for “Hey Buddy” wake word.
- Buddy Copilot tray app (collapsible; expands on input).
- Buddy AI Settings page in COSMIC control center.

## Licenses
- LICENSE includes Buddy‑OS attribution requirement for derivatives.

## Build Artifacts
- ISO name: `Buddy-OS-0.0.0.iso`
- Output path: `build/iso/Buddy-OS-0.0.0.iso`
- SHA256 output to same folder.

## Open Questions / To Decide
- Resolve Ubuntu Core vs Ubuntu Desktop remix conflict in older notes.
- Confirm exact commands for Buddy UI, Buddy Settings, and voice services.

# Repository Guidelines

## Project Structure & Module Organization
Buddy-OS is a spec-first repo with early implementation pieces. Key locations:
- `ABOUT.md` is the canonical product anchor; align new work here first.
- `specs/` holds formal requirements (permissions, UI, build pipeline).
- `buddy/` contains the agent core and CLI entry points.
- `broker/` contains the action execution layer and policy enforcement.
- `ui/` is reserved for Buddy Bar + drawer UI work.
- `snaps/` holds snap packaging definitions for Buddy-OS components.
- `scripts/` contains reproducible build + dev tooling.
- `build/` is for generated artifacts (images, ISOs, logs).
- `assets/`, `images/`, `docs/`, `notes/` hold supporting material.

## Build, Test, and Development Commands
- `scripts/dev/build_buildhost.sh` builds the Ubuntu 24.04 build-host image (Docker/Podman).
- `scripts/dev/run_in_buildhost.sh -- <cmd>` runs commands inside the build-host container.
- `scripts/dev/smoke_test_buildhost.sh` prints required tool versions in the build host.
- `scripts/git_checkpoint.sh "message"` commits (and pushes if origin is set).

## Coding Style & Naming Conventions
- Shell scripts use `bash` with `set -euo pipefail`; keep this pattern for new scripts.
- Python files are plain `*.py` with standard library usage; avoid heavy dependencies unless required.
- Use descriptive, kebab-case filenames for scripts and specs (e.g., `remix_iso_prepare.sh`).

## Testing Guidelines
- There is no automated test framework yet. Use `scripts/dev/smoke_test_buildhost.sh` to verify the build host.
- For new components, document any manual verification steps in `notes/` or the relevant `specs/` file.

## Commit & Pull Request Guidelines
- Commit messages are short and often prefixed by type (e.g., `docs:`, `chore:`, `decision:`).
- Prefer imperative summaries like `build update` or `docs: update model strategy`.
- PRs should include a concise description, link to relevant `specs/` or `notes/`, and screenshots for UI changes.

## Security & Configuration Tips
- `buddy/config/providers.example.json` is safe to commit; real secrets belong in the vault (no plaintext).
- Do not commit large model seed artifacts; only manifests and `sha256` files are allowed.

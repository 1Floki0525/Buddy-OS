# Repository Guidelines

## Project Structure & Module Organization
Buddy-OS is a spec-first repo. Align work to these anchors:
- `ABOUT.md` is the canonical project spec and UX baseline.
- `specs/` defines permissions, UI behavior, providers, build pipeline, and storage rules.
- `buddy/` contains the agent CLI and core logic; `broker/` is the execution layer.
- `snaps/` holds snap packaging for Buddy components and the model assertion.
- `images/rootfs/` is the rootfs overlay applied during ISO build.
- `assets/` stores icons, Plymouth theme assets, and apt repo keys/sources.
- `scripts/build/` and `scripts/dev/` provide reproducible build tooling.
- `build/` is generated output (ISO artifacts, logs, staging).

## Build, Test, and Development Commands
- `scripts/build/setup_iso_toolchain.sh` installs the ISO toolchain and pulls `ubuntu-cdimage`.
- `scripts/build/build_all.sh` builds snaps and the ISO; set `BUILD_ISO=1` to force ISO flow.
- `scripts/build/build_iso.sh` runs the livecd-rootfs pipeline and outputs `build/iso/Buddy-OS-0.0.0.iso`.
- `scripts/build/sync_rootfs_overlay.sh` syncs `images/rootfs/` into the ISO build.
- `scripts/dev/smoke_test_buildhost.sh` prints required tool versions for the build host.
- `scripts/git_checkpoint.sh "message"` commits (and pushes if origin is set).

## Coding Style & Naming Conventions
- Shell scripts use `bash` with `set -euo pipefail`; keep this pattern.
- Python is standard-library first; avoid heavy deps unless spec-mandated.
- File naming: kebab-case for scripts/specs, clear service names for systemd units.

## Testing Guidelines
- No automated test suite yet. Validate with the ISO build logs under `build/logs/`.
- Manual checks should be captured in `notes/DECISIONS.md` or relevant `specs/`.

## Commit & Pull Request Guidelines
- Commit prefixes in history: `build:`, `model:`; follow the same concise, imperative style.
- PRs should reference the relevant `specs/` file and include screenshots for UI changes.

## Security & Configuration Tips
- Providers are configured via GUI only; example config lives in `buddy/config/providers.example.json`.
- Never commit large model seed artifacts; store only manifests and `sha256` in-repo.

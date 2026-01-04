#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OVERLAY_DIR="${ROOT_DIR}/images/rootfs"

mkdir -p \
  "${OVERLAY_DIR}/usr/share/plymouth/themes/buddy-os" \
  "${OVERLAY_DIR}/usr/share/icons/hicolor/256x256/apps" \
  "${OVERLAY_DIR}/usr/share/applications" \
  "${OVERLAY_DIR}/etc/plymouth" \
  "${OVERLAY_DIR}/etc/systemd/system-preset"

cp -f "${ROOT_DIR}/assets/plymouth/buddy-os/"* \
  "${OVERLAY_DIR}/usr/share/plymouth/themes/buddy-os/"
cp -f "${ROOT_DIR}/assets/icons/buddy-ai.png" \
  "${OVERLAY_DIR}/usr/share/icons/hicolor/256x256/apps/buddy-ai.png"
cp -f "${ROOT_DIR}/assets/applications/buddy-ai-settings.desktop" \
  "${OVERLAY_DIR}/usr/share/applications/buddy-ai-settings.desktop"
cp -f "${ROOT_DIR}/assets/applications/buddy-copilot.desktop" \
  "${OVERLAY_DIR}/usr/share/applications/buddy-copilot.desktop"

cat > "${OVERLAY_DIR}/etc/plymouth/plymouthd.conf" <<'EOF'
[Daemon]
Theme=buddy-os
ShowDelay=0
EOF

cat > "${OVERLAY_DIR}/etc/systemd/system-preset/90-buddy-os.preset" <<'EOF'
enable buddy-voice.service
EOF

echo "OK: synced rootfs overlay assets"

#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="buddyos-buildhost:24.04"
DOCKER_BIN="${DOCKER_BIN:-podman}"

echo "== Building build-host image: ${IMAGE_NAME} =="

TMP_DOCKERFILE="$(mktemp)"
cat > "${TMP_DOCKERFILE}" <<'EOF'
FROM docker.io/library/ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Enable all components and install core build tools
RUN sed -i 's/^Components: main$/Components: main restricted universe multiverse/' /etc/apt/sources.list.d/ubuntu.sources || true \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git jq rsync \
    python3 python3-venv python3-pip \
    snapd \
    xorriso squashfs-tools \
    mtools dosfstools \
    grub-pc-bin grub-efi-amd64-bin \
    qemu-utils parted e2fsprogs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
CMD ["bash"]
EOF

"${DOCKER_BIN}" build -t "${IMAGE_NAME}" -f "${TMP_DOCKERFILE}" .

rm -f "${TMP_DOCKERFILE}"

echo
echo "OK: built ${IMAGE_NAME}"

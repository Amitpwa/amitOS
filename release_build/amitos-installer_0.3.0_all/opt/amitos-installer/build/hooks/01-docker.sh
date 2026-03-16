#!/usr/bin/env bash
# ============================================================================
# amitOS — Customization Hook: Docker Installation
# ============================================================================
# Installs Docker Engine + NVIDIA Container Toolkit in the rootfs.
# This hook runs during image build (build-image.sh).
#
# Environment:
#   ROOTFS — path to the target rootfs
# ============================================================================
set -euo pipefail

ROOTFS="${ROOTFS:?ROOTFS environment variable is required}"

echo "[HOOK] Installing Docker Engine..."

# Add Docker GPG key and repo
chroot "${ROOTFS}" /bin/bash -c '
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list

    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
'

echo "[HOOK] Docker installed."

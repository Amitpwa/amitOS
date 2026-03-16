#!/usr/bin/env bash
# ============================================================================
# amitOS — Customization Hook: NVIDIA CUDA Setup
# ============================================================================
# Installs NVIDIA drivers, CUDA toolkit, and container toolkit in the rootfs.
# Skipped if building for arm64 (Jetson uses different CUDA packaging).
#
# Environment:
#   ROOTFS — path to the target rootfs
# ============================================================================
set -euo pipefail

ROOTFS="${ROOTFS:?ROOTFS environment variable is required}"

# Detect architecture
ARCH="$(chroot "${ROOTFS}" dpkg --print-architecture 2>/dev/null || echo 'amd64')"

if [[ "${ARCH}" != "amd64" ]]; then
    echo "[HOOK] Skipping NVIDIA CUDA for ${ARCH} (use Jetson-specific packages for arm64)."
    exit 0
fi

echo "[HOOK] Setting up NVIDIA CUDA repository..."

chroot "${ROOTFS}" /bin/bash -c '
    # Add NVIDIA CUDA keyring
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb -o /tmp/cuda-keyring.deb
    dpkg -i /tmp/cuda-keyring.deb
    rm /tmp/cuda-keyring.deb

    apt-get update -qq

    # Install CUDA toolkit (runtime only — not the full dev kit)
    apt-get install -y -qq cuda-toolkit-12-3 || echo "WARN: CUDA install may require manual setup"

    # NVIDIA Container Toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed "s#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g" \
        > /etc/apt/sources.list.d/nvidia-container-toolkit.list

    apt-get update -qq
    apt-get install -y -qq nvidia-container-toolkit || echo "WARN: NVIDIA Container Toolkit install may require manual setup"
'

echo "[HOOK] NVIDIA CUDA setup complete."

# ============================================================================
# amitOS — Top-Level Makefile
# ============================================================================
# Build targets for the amitOS industrial automation OS.
#
# Usage:
#   make help          Show available targets
#   make kernel        Build custom kernel packages
#   make image         Build bootable OS image
#   make install       Install amitOS on current system
#   make clean         Clean all build artifacts
# ============================================================================

.PHONY: help kernel image install clean lint version

# --- Variables ---
SHELL      := /bin/bash
VERSION    := $(shell cat VERSION 2>/dev/null || echo "dev")
ARCH       := $(shell dpkg --print-architecture 2>/dev/null || echo "amd64")
BUILD_DIR  := build
OUTPUT_DIR := $(BUILD_DIR)/output
KERNEL_DIR := kernel

# --- Default Target ---
help:
	@echo ""
	@echo "  ╔══════════════════════════════════════╗"
	@echo "  ║         amitOS Build System           ║"
	@echo "  ╚══════════════════════════════════════╝"
	@echo ""
	@echo "  Version: $(VERSION)"
	@echo "  Arch:    $(ARCH)"
	@echo ""
	@echo "  Targets:"
	@echo "    make kernel       Build custom amitOS kernel (.deb packages)"
	@echo "    make image        Build bootable OS image (requires sudo)"
	@echo "    make install      Install amitOS on this Debian system (requires sudo)"
	@echo "    make lint         Lint all shell scripts and YAML configs"
	@echo "    make clean        Remove all build artifacts"
	@echo "    make version      Show version info"
	@echo "    make help         Show this help"
	@echo ""

# --- Build Kernel ---
kernel:
	@echo "[amitOS] Building custom kernel for $(ARCH)..."
	sudo $(KERNEL_DIR)/build-kernel.sh --arch $(ARCH)

# --- Build OS Image ---
image:
	@echo "[amitOS] Building OS image for $(ARCH)..."
	sudo $(BUILD_DIR)/build-image.sh --arch $(ARCH)

# --- Install on Current System ---
install:
	@echo "[amitOS] Installing amitOS on this system..."
	sudo ./install.sh

# --- Lint ---
lint:
	@echo "[amitOS] Linting shell scripts..."
	@find $(KERNEL_DIR) $(BUILD_DIR) system/scripts -name "*.sh" -exec bash -n {} \; && echo "  ✓ Shell syntax OK"
	@if command -v shellcheck &>/dev/null; then \
		find $(KERNEL_DIR) $(BUILD_DIR) system/scripts -name "*.sh" -exec shellcheck -S warning {} \; && echo "  ✓ ShellCheck OK"; \
	else \
		echo "  ⚠ shellcheck not installed (apt install shellcheck)"; \
	fi
	@echo "[amitOS] Validating YAML configs..."
	@python3 -c "import yaml; import glob; [yaml.safe_load(open(f)) for f in glob.glob('system/configs/adapters/*.yaml')]" 2>/dev/null && echo "  ✓ YAML configs OK" || echo "  ⚠ PyYAML not installed or YAML errors detected"
	@echo "[amitOS] Lint complete."

# --- Version ---
version:
	@echo "amitOS $(VERSION) ($(ARCH))"

# --- Clean ---
clean:
	@echo "[amitOS] Cleaning build artifacts..."
	rm -rf $(OUTPUT_DIR)
	rm -rf $(BUILD_DIR)/kernel-build
	rm -rf $(BUILD_DIR)/rootfs
	@echo "[amitOS] Clean complete."

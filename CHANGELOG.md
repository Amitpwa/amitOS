# Changelog

## [Unreleased] — Kernel & Build Infrastructure

### Added
- **Kernel configuration fragment** (`kernel/config-amitos.fragment`) — PREEMPT, CAN bus, IIO sensors, USB-serial, SPI/I2C/GPIO, container support, GPU infrastructure, security hardening
- **Kernel build script** (`kernel/build-kernel.sh`) — automated kernel compilation from Debian sources (amd64 + arm64)
- **Kernel runtime tuning** (`kernel/sysctl-amitos.conf`) — network, scheduling, memory, and security optimizations
- **Kernel module loader** (`kernel/modules-load.conf`) — auto-load overlay, br_netfilter, nf_tables at boot
- **systemd services** — OPC UA server, 5 adapter services (Modbus, MQTT, Siemens S7, BACnet, REST bridge), health monitor timer
- **Adapter YAML configs** — production-ready configs for all 5 built-in adapters with OPC UA node mappings
- **OPC UA server config** (`system/configs/opcua/server.xml`) — dual endpoints, cert paths, session limits, mDNS discovery
- **Nginx reverse proxy config** — TLS, rate limiting, security headers, REST API + Dashboard upstreams
- **Utility scripts** — `amitos-info` (system info), `amitos-check` (health check), `amitos-adapter` (adapter management CLI)
- **OS image builder** (`build/build-image.sh`) — debootstrap-based image generation with GPT partitioning
- **Install script** (`install.sh`) — transforms bare Debian into amitOS with 8-step automated setup
- **Makefile** — top-level build orchestration (`make kernel`, `make image`, `make install`, `make lint`, `make clean`)
- **Kernel documentation** (`docs/KERNEL.md`) — config overview, build instructions, sysctl guide, RT-PREEMPT upgrade path
- **Updated architecture** (`docs/ARCHITECTURE.md`) — added Kernel Layer and Build System sections

All notable changes to **amitOS** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Web-based system dashboard
- OTA (Over-The-Air) update system
- Adapter Marketplace
- Pro License features (advanced security, remote diagnostics)

---

## [0.2.0] - 2026-03-12

### Added
- Full CUDA provisioning for computer vision libraries (OpenCV with CUDA modules)
- Pre-installed AI libraries: cuDNN, NCCL, PyTorch (CUDA), TensorFlow-GPU
- Docker and container-native development support
- ONNX runtime and TensorFlow Lite pre-installed
- GPU acceleration support for NVIDIA GPUs (CUDA 11+)

### Changed
- Improved system performance for AI workloads on edge devices
- Enhanced GPU driver installation scripts

---

## [0.1.0] - 2025-11-01

### Added
- Initial release of **amitOS** — Debian-based industrial automation OS
- Native **OPC UA & OPC DA** support with auto-discovery
- **Netplan** integration for intuitive network configuration
- **Nginx** reverse proxy with TLS certificate tooling
- Built-in firewall and VLAN support
- Adapter Framework with 5 plug-and-play adapters:
  - Modbus TCP/RTU
  - MQTT v3.1 / v5
  - Siemens S7 PLC
  - BACnet/IP
  - REST API Bridge
- MIT License
- Initial README and project documentation

---

[Unreleased]: https://github.com/Amitpwa/amitOS/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/Amitpwa/amitOS/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/Amitpwa/amitOS/releases/tag/v0.1.0

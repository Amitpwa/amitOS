# Changelog

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

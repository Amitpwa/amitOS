# amitOS Roadmap

This document outlines the feature roadmap for **amitOS** across planned releases. Features are subject to change based on community feedback.

---

## Release Overview

| Version | Theme | Target |
|---|---|---|
| **v0.1.0** | Foundation | ✅ Released Nov 2025 |
| **v0.2.0** | AI & GPU Runtime | ✅ Released Mar 2026 |
| **v0.3.0** | Dashboard & SDK | 🔄 In Progress |
| **v0.4.0** | OTA & Remote Management | 📅 Q3 2026 |
| **v1.0.0** | Production-Ready Stable | 📅 Q4 2026 |

---

## v0.1.0 — Foundation ✅

*Released: November 2025*

| Feature | Status |
|---|---|
| Hardened Debian core OS | ✅ Done |
| OPC UA server/client (auto-discovery) | ✅ Done |
| OPC DA client support | ✅ Done |
| Netplan network configuration | ✅ Done |
| Nginx reverse proxy with TLS | ✅ Done |
| Built-in firewall (nftables) | ✅ Done |
| VLAN support | ✅ Done |
| Modbus Adapter | ✅ Done |
| MQTT Adapter | ✅ Done |
| Siemens S7 Adapter | ✅ Done |
| BACnet Adapter | ✅ Done |
| REST API Bridge Adapter | ✅ Done |
| MIT License | ✅ Done |

---

## v0.2.0 — AI & GPU Runtime ✅

*Released: March 2026*

| Feature | Status |
|---|---|
| CUDA 11+ full provisioning | ✅ Done |
| cuDNN & NCCL libraries | ✅ Done |
| PyTorch with CUDA build | ✅ Done |
| TensorFlow-GPU | ✅ Done |
| OpenCV with CUDA modules | ✅ Done |
| ONNX Runtime (CUDA provider) | ✅ Done |
| TensorFlow Lite runtime | ✅ Done |
| Docker & container runtime | ✅ Done |
| Python 3.10+ pre-installed | ✅ Done |

---

## v0.3.0 — Dashboard & SDK 🔄

*Target: Q2 2026*

| Feature | Status | Notes |
|---|---|---|
| Web-based system dashboard | 🔄 In Progress | React + REST API backend |
| Adapter SDK (Python base class) | 🔄 In Progress | Standardize custom adapter development |
| Adapter SDK test harness | 📅 Planned | Unit testing toolkit for adapters |
| OPC UA node browser in dashboard | 📅 Planned | Visual OPC UA node tree |
| System metrics panel | 📅 Planned | CPU, RAM, GPU, network stats |
| Adapter marketplace (alpha) | 📅 Planned | Community-contributed adapters |

---

## v0.4.0 — OTA & Remote Management 📅

*Target: Q3 2026*

| Feature | Status | Notes |
|---|---|---|
| OTA update system | 📅 Planned | Atomic A/B partition updates |
| Remote diagnostics agent | 📅 Planned | Secure agent with encrypted tunnel |
| Remote config push | 📅 Planned | Push adapter and network configs remotely |
| Rollback on failed update | 📅 Planned | Auto-revert if health checks fail |
| Fleet management dashboard | 📅 Planned | Manage multiple amitOS devices |

---

## v1.0.0 — Production-Ready Stable 📅

*Target: Q4 2026*

| Feature | Status | Notes |
|---|---|---|
| Long-Term Support (LTS) designation | 📅 Planned | 2-year security patch commitment |
| Formal hardware certification | 📅 Planned | Certified hardware list published |
| Pro License with commercial support | 📅 Planned | SLA-based support tiers |
| Formal adapter marketplace launch | 📅 Planned | Paid and free adapter listings |
| FIPS 140-2 compliance option | 📅 Planned | For regulated industries |
| ARM64 optimized image | 📅 Planned | Raspberry Pi / NVIDIA Jetson |

---

## Community Requested Features

Have a feature idea? [Open a Feature Request](https://github.com/Amitpwa/amitOS/issues/new?template=feature_request.md)!

| Feature | Requested By | Priority |
|---|---|---|
| DNP3 Adapter | Community | Medium |
| EtherNet/IP Adapter | Community | High |
| PROFINET Adapter | Community | High |
| Kubernetes integration | Community | Low |
| FIDO2 / WebAuthn login | Community | Medium |

---

## Legend

| Icon | Meaning |
|---|---|
| ✅ Done | Implemented and available |
| 🔄 In Progress | Actively being developed |
| 📅 Planned | Scheduled for a future release |
| ❌ Cancelled | Will not be implemented |

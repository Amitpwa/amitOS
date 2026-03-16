# Decision Architecture Record (DAR)

**Project**: amitOS — Industrial Automation OS  
**Author**: Ashutosh Pandey (@Amitpwa)  
**Last Updated**: 2026-03-12  
**Status**: Active (living document — update when decisions change)

> This document captures all major architectural and technology decisions made for amitOS, along with the rationale, alternatives considered, and trade-offs accepted. It exists so that every contributor — human or AI — can make consistent decisions aligned with the project's direction.

---

## Table of Contents

1. [OS Base Distribution](#1-os-base-distribution)
2. [Linux Kernel Strategy](#2-linux-kernel-strategy)
3. [OPC UA Protocol Stack](#3-opc-ua-protocol-stack)
4. [AI Runtime Stack](#4-ai-runtime-stack)
5. [GPU Compute Platform](#5-gpu-compute-platform)
6. [Adapter Framework Language](#6-adapter-framework-language)
7. [Network Configuration](#7-network-configuration)
8. [Reverse Proxy](#8-reverse-proxy)
9. [Firewall](#9-firewall)
10. [Container Runtime](#10-container-runtime)
11. [Init System](#11-init-system)
12. [Package Management](#12-package-management)
13. [Web Dashboard Framework](#13-web-dashboard-framework)
14. [Versioning & Release Strategy](#14-versioning--release-strategy)
15. [License](#15-license)

---

## 1. OS Base Distribution

**Decision**: **Debian Stable (Bookworm, 12.x)**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **Debian** ✅ | Yes | **Chosen** |
| Ubuntu LTS | Yes | Bigger footprint; Snap pre-installed adds overhead; Debian is the upstream |
| Alpine Linux | Yes | Musl libc causes compatibility issues with CUDA/NVIDIA drivers and many industrial libs |
| Arch Linux | Yes | Rolling release = unpredictability in production industrial deployments |
| Yocto / Buildroot | Yes | Too much maintenance overhead for this team size at current stage |

**Rationale**:
- Debian is the most stable, well-supported base for embedded/industrial Linux
- Industry-standard: used in PLC gateways, edge servers, and IoT devices
- `apt` ecosystem covers all needed packages (CUDA, OPC UA, Python, Nginx)
- Long support cycle aligns with industrial deployment timelines (5–10 years)
- Minimal default installation reduces attack surface

**Trade-offs accepted**:
- Slightly older package versions than Ubuntu; mitigated via official NVIDIA, OPC Foundation, and PyPI repos for bleeding-edge components

---

## 2. Linux Kernel Strategy

**Decision**: **Standard Debian Kernel + `PREEMPT` patch where needed**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **Standard Debian kernel (PREEMPT)** ✅ | Yes | **Chosen** |
| RT-PREEMPT (full real-time) | Yes | Not needed for current use cases (soft real-time via OPC UA polling is sufficient) |
| Xenomai (RTOS co-kernel) | Yes | Adds significant complexity; requires custom toolchain |
| Custom kernel build | Yes | Maintenance burden too high for current team; use only if hard RT required |
| PREEMPT_RT fully patched | Future | Will evaluate for v1.0 if hard real-time customers emerge |

**Rationale**:
- OPC UA polling at 500ms–1s intervals is **soft real-time** — standard `PREEMPT` kernel handles this fine
- CUDA and NVIDIA drivers are fully tested against standard Debian kernels
- Reduces maintenance burden significantly
- If sub-1ms determinism is required in a future version, RT-PREEMPT will be re-evaluated

**Constraints**:
- Do NOT modify the kernel outside of standard Debian kernel headers unless a specific hard-RT customer requirement is documented in this DAR
- Any kernel module additions must be documented here

---

## 3. OPC UA Protocol Stack

**Decision**: **open62541 (C library) or node-opcua (Node.js) — C library preferred for server**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **open62541** ✅ | Yes | **Chosen for server** — open source, C, high performance, OPC Foundation certified |
| node-opcua | Yes | JavaScript-based; fine for tooling but too heavyweight for server runtime |
| Python asyncua | Yes | Good for adapters and testing; used in adapter layer |
| Commercial UNIFIED AUTOMATION stack | Yes | Proprietary; contradicts open-source mission |
| Eclipse Milo (Java) | Yes | JVM overhead; not suitable for edge devices with 2GB RAM |

**Rationale**:
- `open62541` is the reference open-source implementation; IEC 62541 compliant
- Written in C — minimal memory footprint, runs on 2GB RAM systems
- No licensing fees; active community
- `asyncua` (Python) is used in adapter-side client connections due to ease of use

**Key versions**:
- open62541: `>= 1.3.x`
- asyncua: `>= 1.0`

---

## 4. AI Runtime Stack

**Decision**: **ONNX Runtime (primary) + TensorFlow Lite (lightweight) + PyTorch (training/development)**

| Component | Decision | Rationale |
|---|---|---|
| **Primary inference** | ONNX Runtime | Framework-agnostic; best CUDA performance; widely supported |
| **Lightweight inference** | TF-Lite | For resource-constrained devices without GPU |
| **Development / Training** | PyTorch | Industry standard; easiest export to ONNX |
| **Computer vision** | OpenCV (CUDA build) | Industry standard; CUDA acceleration essential for edge CV |
| **Deep learning libs** | cuDNN + NCCL | Required for CUDA-accelerated training/inference |

**Alternatives NOT chosen**:

| Option | Reason Not Chosen |
|---|---|
| TensorRT (NVIDIA-only) | Lock-in to NVIDIA hardware; ONNX Runtime covers this well via CUDA EP |
| OpenVINO (Intel) | Intel-specific; not aligned with NVIDIA GPU focus |
| Triton Inference Server | Too heavy for edge devices; designed for data centers |
| CoreML / TFLite alone | Platform-specific or insufficient for industrial use cases |

**Rationale**:
- ONNX Runtime allows models trained in any framework (PyTorch, TF, sklearn) to run efficiently
- Keeps the system framework-agnostic — users aren't locked into one ML framework
- TF-Lite provides a lightweight fallback for CPU-only edge devices

---

## 5. GPU Compute Platform

**Decision**: **NVIDIA CUDA (primary); CPU-only fallback for non-GPU hardware**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **NVIDIA CUDA** ✅ | Yes | **Chosen** — dominant in industrial AI; best ecosystem |
| AMD ROCm | Yes | Smaller ecosystem; fewer industrial AI deployments; worse driver stability on Debian |
| Intel Arc / OpenCL | Yes | Not mature enough; limited in edge industrial segment |
| CPU-only | Fallback | Always supported as default fallback when no GPU present |

**Rationale**:
- NVIDIA GPUs dominate the industrial edge AI market (Jetson, RTX for workstations)
- CUDA ecosystem (cuDNN, NCCL, TensorRT, OpenCV CUDA) is the most complete
- AMD ROCm support for Debian is less stable and lags behind on Debian kernels

**Constraints**:
- All CUDA code must have a CPU fallback path
- CUDA version target: `>= 11.8` (lowest common denominator for modern Jetson + desktop GPUs)
- cuDNN version must match the CUDA version pinned in `install.sh`

---

## 6. Adapter Framework Language

**Decision**: **Python (primary) with YAML configuration files**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **Python** ✅ | Yes | **Chosen** — fastest development cycle; best protocol library ecosystem |
| Go | Yes | Better performance, but fewer industrial protocol libraries; steeper contributor barrier |
| Rust | Yes | Best performance and safety, but very steep learning curve; few industrial protocol crates |
| C/C++ | Yes | Too low-level for rapid adapter development |
| Node.js | Yes | Good async, but inconsistent in industrial deployments |

**Rationale**:
- Python has the richest ecosystem for industrial protocols: `pymodbus`, `asyncua`, `python-snap7`, `bacpypes3`, `paho-mqtt`
- Lowest barrier to entry for industrial engineers and contributors
- AI integration (ONNX, PyTorch) is native Python — no bridging needed
- Performance is sufficient for adapter polling rates (50ms–1s)

**Constraints**:
- Python `>= 3.10` (use type hints, `asyncio` where appropriate)
- All adapters must be structured as `systemd` services
- Configuration via YAML (never hardcode connection params in Python files)
- Use `asyncio` for I/O-bound adapters (networking, serial)

---

## 7. Network Configuration

**Decision**: **Netplan (with `networkd` renderer)**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **Netplan + networkd** ✅ | Yes | **Chosen** — declarative, Debian-native, human-readable YAML |
| NetworkManager | Yes | More GUI-oriented; heavier; designed for desktop, not headless servers |
| `/etc/network/interfaces` | Yes | Legacy; not suitable for complex multi-interface/VLAN configs |
| systemd-networkd alone | Yes | More verbose; Netplan is a clean abstraction layer over it |

**Rationale**:
- Netplan is the modern Debian/Ubuntu standard for server network config
- YAML-based = version-controllable, diff-friendly, easy to audit
- Native VLAN, bonding, and bridge support
- Works headlessly on servers and edge devices

---

## 8. Reverse Proxy

**Decision**: **Nginx**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **Nginx** ✅ | Yes | **Chosen** — battle-tested, lightweight, industry standard |
| Caddy | Yes | Auto-TLS is nice, but less familiar to industrial engineers; smaller ecosystem |
| HAProxy | Yes | Excellent for TCP load balancing, but overkill for the current use case |
| Apache | Yes | Too heavyweight and configuration-heavy vs Nginx |
| Traefik | Yes | Container-native; adds unnecessary complexity for this use case |

**Rationale**:
- Nginx is the most widely deployed web/proxy server in industrial and enterprise environments
- Excellent performance for static files + reverse proxy
- TLS termination, basic auth, and rate limiting built-in
- Large documentation base and community familiarity

---

## 9. Firewall

**Decision**: **nftables**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **nftables** ✅ | Yes | **Chosen** — modern Linux standard, replaces iptables |
| iptables | Yes | Legacy; being deprecated in favor of nftables on Debian 12+ |
| UFW | Yes | User-friendly wrapper, but abstracts too much for complex industrial rules |
| firewalld | Yes | Zone-based model adds complexity; better suited for enterprise servers |

**Rationale**:
- nftables is the default in Debian 12+ and the Linux kernel firewall standard going forward
- Better performance than iptables via unified ruleset evaluation
- Supports IPv4 + IPv6 in a single ruleset

---

## 10. Container Runtime

**Decision**: **Docker Engine (with NVIDIA Container Toolkit)**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **Docker Engine** ✅ | Yes | **Chosen** — widest ecosystem; best GPU support via NVIDIA toolkit |
| Podman | Yes | Rootless is good, but GPU support is less mature; less familiar to target users |
| containerd alone | Yes | Low-level; no CLI UX for developers; Docker uses containerd under the hood |
| LXC/LXD | Yes | System containers, not application containers; different use case |

**Rationale**:
- Docker is the universal standard for containerized AI workload deployment at the edge
- NVIDIA Container Toolkit (`nvidia-docker2`) provides seamless GPU passthrough
- Docker Compose support simplifies multi-service AI deployments
- Largest ecosystem of pre-built images (CUDA base images, ML frameworks)

---

## 11. Init System

**Decision**: **systemd**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **systemd** ✅ | Yes | **Chosen** — Debian default; required by Netplan and Nginx |
| OpenRC | Yes | Not Debian default; would require significant rework |
| s6 / runit | Yes | Better for containers, but not suitable for full OS with systemd-dependent tools |
| SysVinit | Yes | Legacy; not compatible with modern Netplan, CUDA, and networking stack |

**Rationale**:
- systemd is the Debian standard and required by Netplan, Nginx, and NVIDIA GPU services
- Provides service dependency management, socket activation, journal logging, and watchdog support
- All adapters are managed as systemd units — this is non-negotiable

---

## 12. Package Management

**Decision**: **apt (Debian package manager) + pip (Python packages) + Docker (containerized AI workloads)**

| Layer | Tool | Scope |
|---|---|---|
| OS packages | `apt` | All system-level packages |
| Python libraries | `pip` (in venv or system) | AI/adapter Python dependencies |
| Containerized workloads | `docker` | Pre-built AI model containers |
| Firmware / Drivers | NVIDIA `.run` or `.deb` | CUDA, cuDNN, drivers |

**NOT using**: snap, flatpak, AppImage (add overhead; inconsistent in headless industrial environments).

---

## 13. Web Dashboard Framework

**Decision**: **React (with REST API backend in Python/FastAPI)** *(planned for v0.3.0)*

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **React** ✅ | Yes | **Chosen** — largest ecosystem; best charting libraries for industrial dashboards |
| Vue.js | Yes | Good alternative; slightly smaller ecosystem for industrial dashboard components |
| Svelte | Yes | Excellent performance, but smaller component ecosystem |
| Angular | Yes | Too heavyweight and opinionated for this use case |

**Backend**:
- **FastAPI** (Python) for the REST API backend
- Connects to OPC UA server, adapter bus, and system metrics

**Rationale**:
- React + FastAPI allows shared Python expertise across adapters and backend
- Rich charting libraries (Recharts, Tremor, Apache ECharts) for SCADA-style dashboards

---

## 14. Versioning & Release Strategy

**Decision**: **Semantic Versioning (SemVer) + GitHub Releases + Keep-a-Changelog**

| Aspect | Decision |
|---|---|
| Version format | `vMAJOR.MINOR.PATCH` (SemVer) |
| Changelog format | [Keep a Changelog](https://keepachangelog.com/) |
| Release artifacts | GitHub Releases with tagged commits on `production` |
| Branch-to-release | `release/vX.Y.Z` → merge into `production` → tag |
| Pre-releases | `-alpha`, `-beta`, `-rc.N` suffixes |

---

## 15. License

**Decision**: **MIT License**

| Option | Considered | Reason Not Chosen |
|---|---|---|
| **MIT** ✅ | Yes | **Chosen** — maximum adoption, minimal friction |
| Apache 2.0 | Yes | Good for patents, but slightly more complex for contributors |
| GPL v2/v3 | Yes | Copyleft requirement may deter commercial integrators |
| LGPL | Yes | Complex for OS-level software |
| BSL (Business Source License) | No | Not truly open source |

**Rationale**:
- MIT maximizes adoption in industrial settings where companies are reluctant to open-source their products
- Compatible with all dependencies (Debian, CUDA libs, ONNX, etc.)
- Pro features (OTA, remote management) will be offered as a separate commercial service layer, not as proprietary code in this repo

---

## Decision Change Protocol

If a major architectural decision needs to change:

1. Open a GitHub Issue labeled `decision-change` with full justification
2. Discuss in the issue for at least **7 days** (or until maintainer approval)
3. Update this DAR with the new decision and the date
4. Note the previous decision in the table as "previously used" with a migration note
5. Update `CHANGELOG.md` with the architectural change

---

*This is a living document. Keep it up to date as the project evolves.*

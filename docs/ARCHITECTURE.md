# amitOS Architecture Overview

This document describes the layered system architecture of **amitOS**, an industrial automation OS built on a hardened Debian base.

---

## System Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    USER / APPLICATIONS                       │
│           (SCADA, HMI, Custom Apps, Dashboards)             │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    ADAPTER LAYER                             │
│  Modbus │ MQTT │ Siemens S7 │ BACnet │ REST API Bridge      │
│             Custom Adapter SDK (plug-and-play)               │
└──────────┬───────────────────────────────┬──────────────────┘
           │                               │
┌──────────▼──────────┐      ┌─────────────▼───────────────── ┐
│  INDUSTRIAL         │      │   AI / GPU RUNTIME LAYER       │
│  PROTOCOL LAYER     │      │   Python · ONNX · TF-Lite      │
│  OPC UA Server/     │      │   PyTorch · TensorFlow-GPU     │
│  Client · OPC DA    │      │   OpenCV (CUDA) · cuDNN · NCCL │
│  Real-time SCADA    │      │   Docker / Container Runtime   │
└──────────┬──────────┘      └─────────────┬──────────────────┘
           │                               │
┌──────────▼───────────────────────────────▼──────────────────┐
│                    NETWORKING LAYER                          │
│         Netplan · Nginx (Reverse Proxy) · TLS Tools         │
│              Firewall · VLAN Support · Adapters             │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    CORE OS LAYER                             │
│            Hardened Debian Linux (x86_64 / ARMv8)           │
│     System Services · Package Management · Security Policies │
└─────────────────────────────────────────────────────────────┘
```

---

## Layer Descriptions

### 1. Core OS Layer

The foundation of amitOS is a **hardened Debian Linux** base system.

- **Architecture support**: x86_64 and ARMv8
- **Init system**: systemd
- **Package management**: apt with pinned security sources
- **Security hardening**: Reduced attack surface, minimal installed packages, AppArmor profiles
- **Kernel**: Patched for real-time or near-real-time performance where required

### 2. Networking Layer

Built-in networking capabilities designed for industrial environments:

| Component | Purpose |
|---|---|
| **Netplan** | Declarative network configuration (YAML-based) |
| **Nginx** | Reverse proxy, load balancing, SSL termination |
| **TLS Tools** | Certificate generation, management, and renewal |
| **Firewall (nftables)** | Stateful packet filtering |
| **VLAN Support** | Layer 2 network segmentation |

See [NETWORKING.md](NETWORKING.md) for configuration details.

### 3. Industrial Protocol Layer

Native support for industrial communication standards:

| Protocol | Mode | Use Case |
|---|---|---|
| **OPC UA** | Server + Client | Modern SCADA, IoT integration |
| **OPC DA** | Client | Legacy PLC / DCS systems |

Key capabilities:
- Auto-discovery of OPC UA servers on the network
- Session management, subscription handling
- Real-time data publishing to connected clients
- Certificate-based authentication for OPC UA

### 4. AI / GPU Runtime Layer

A complete AI inference stack pre-installed on the OS:

| Component | Purpose |
|---|---|
| **Python 3.10+** | Primary scripting language |
| **ONNX Runtime** | Cross-framework model inference |
| **TensorFlow Lite** | Lightweight on-device inference |
| **PyTorch (CUDA)** | GPU-accelerated training & inference |
| **TensorFlow-GPU** | GPU-accelerated inference |
| **OpenCV (CUDA)** | Computer vision with GPU acceleration |
| **cuDNN / NCCL** | NVIDIA deep learning libraries |
| **Docker** | Container-native AI deployment |

See [AI_GPU.md](AI_GPU.md) for setup and usage.

### 5. Adapter Layer

A **plug-and-play adapter framework** that bridges industrial protocols to the application layer:

- Each adapter is an independent, self-contained module
- Adapters communicate via a shared internal message bus
- Built-in adapters: Modbus, MQTT, Siemens S7, BACnet, REST API Bridge
- Custom adapters can be written using the Adapter SDK

See [ADAPTERS.md](ADAPTERS.md) for the adapter framework guide.

### 6. Application Layer

The topmost layer where user applications, dashboards, and SCADA systems interface with amitOS:

- Web-based system dashboard *(in development)*
- REST API for external integrations
- Event-driven hooks via MQTT or OPC UA subscriptions

---

## Data Flow Example

```
PLC (Modbus RTU)
      │
      ▼
Modbus Adapter  ──►  Internal Message Bus  ──►  OPC UA Server
                                                      │
                                                      ▼
                                              SCADA / HMI Client
                                                      │
                                                      ▼
                                              AI Inference Engine (ONNX)
                                                      │
                                                      ▼
                                              Alert / Action via REST API
```

---

## Key Design Principles

1. **Modularity** — Every major subsystem is an independent, replaceable component
2. **Security First** — Minimal attack surface, TLS everywhere, firewall by default
3. **Edge-Optimized** — Designed to run on resource-constrained edge hardware
4. **Protocol Agnostic** — Adapters abstract away protocol differences
5. **AI-Native** — AI inference is a first-class citizen, not an afterthought

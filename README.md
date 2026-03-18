<div align="center">

<img src="assets/amitos.svg" alt="amitOS Logo" width="200">

# amitOS

**Industrial Automation OS · Edge AI · GPU-Powered**

[![License: MIT](https://img.shields.io/badge/License-MIT-cyan.svg)](LICENSE)
[![Debian](https://img.shields.io/badge/Base-Debian%20Bookworm-blue.svg)](https://www.debian.org/)
[![CUDA](https://img.shields.io/badge/GPU-CUDA%2011%2B-green.svg)](docs/AI_GPU.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

</div>

---

**amitOS** is a full, standalone **industrial operating system** built specifically for edge computing and automation. While it is built upon a hardened Debian Linux core, it is a complete OS replacement with a custom-tuned kernel, the unique `amitfs` filesystem layer, and built-in edge intelligence.

## 🚀 Key Features

### 🔌 Industrial Protocols – Native
- ✅ **OPC UA & OPC DA** support out-of-the-box
- ✅ Auto-discovery, client/server support
- ✅ Real-time data handling for SCADA & PLC systems

### 🌐 Optimized Networking Stack
- 🧠 Built-in support for **Netplan** for intuitive network configuration
- 🔒 Secure-by-default with **Nginx** reverse proxy and TLS certificate tools
- 🔗 Adapter-based system integration

### 🤖 AI-Ready & GPU-Accelerated
- Pre-installed Python + ONNX + TensorFlow Lite
- **Full CUDA support** for NVIDIA GPUs
- Integrated support for:
  - PyTorch (with CUDA acceleration)
  - TensorFlow-GPU
  - OpenCV with CUDA modules
  - cuDNN and NCCL
- Docker & container-native development support
- Simple runtime environment for deploying AI on the edge

### 🖥️ User Experience & Desktop GUI
- **GUI Installer Setup Wizard** for a frictionless installation experience
- **Post-Installation Desktop GUI** (XFCE4) available via `--desktop` flag
- Headless options still fully supported for minimal edge deployments

### 💽 amitFS — Universal Filesystem
- Built-in **amitFS framework** supporting ALL major filesystems seamlessly:
  - Linux (EXT4, BTRFS, XFS)
  - Windows & Removables (NTFS3, FAT32, exFAT)
  - Flash-optimized (F2FS)
- Time-series optimized for high-speed industrial data logging

### 🔄 Adapter Framework
Comes bundled with **5+ plug-and-play adapters**, including:
- Modbus
- MQTT
- Siemens S7
- BACnet
- REST API Bridge

### 🔐 Security & Control
- Built-in firewall and VLAN support
- Reverse proxy configuration via Nginx GUI
- Remote diagnostics, OTA updates (Pro license)

---

## 🧰 System Requirements

| Component         | Minimum Requirement         |
|------------------|-----------------------------|
| CPU              | x86_64 or ARMv8             |
| RAM              | 2 GB                        |
| Storage          | 8 GB (SSD recommended)      |
| GPU (Optional)   | NVIDIA GPU with CUDA 11+    |
| Network          | Ethernet or Wi-Fi           |

---

## 💼 Licensing

- 🔓 **Community Edition**: Free to use for learning, testing, and PoCs
- 💼 **Pro License** (Coming Soon):
  - Advanced security tools
  - OTA updates and remote diagnostics
  - Commercial support
  - Adapter marketplace access

---

## 📦 Installation

> **🔥 Want to test-drive amitOS right now?** Check out the [amitOS In Action: 5-Minute Practical Guide](docs/AMITOS_IN_ACTION.md) for a step-by-step tutorial on compiling the OS image and booting it today!

As a full Operating System, amitOS is designed to be flashed to a bare-metal device or run in a virtual machine as a comprehensive environment.

**👉 See the full [Installation Guide](docs/INSTALLATION.md) for detailed instructions on building and flashing bootable OS images (`.img`).**

### Building the Bootable OS Image (Bare-Metal / VM)

Use the built-in image builder to compile a raw `.img` file from scratch that you can flash to a target Industrial PC or USB Drive.

```bash
git clone https://github.com/Amitpwa/amitOS.git
cd amitOS

# Build the default x86_64 raw OS image
make image

# Write the image to your USB Drive/SD Card (for physical hardware)
sudo dd if=build/output/amitOS-0.3.0-dev-amd64.img of=/dev/sdX bs=4M status=progress
```

### In-Place System Transformation (Legacy)

If you already have a live server running Debian 12 and cannot wipe the drives, you can use our script to mutate the existing Debian OS into amitOS:

```bash
git clone https://github.com/Amitpwa/amitOS.git
cd amitOS
sudo ./gui-installer.sh
```

## 🛠️ Roadmap
 Debian-based Core OS

 OPC UA/DA stack integration

 Netplan & Nginx built-in

 CUDA support and GPU-ready libraries

 Modular Adapter SDK

 Web-based system dashboard

 OTA update system

## 🤝 Contributing
We welcome contributions from developers, engineers, and system integrators. Please check out the CONTRIBUTING.md file for details.

## 📧 Contact
Project Lead: ashutoshPandey https://linkedin.com/in/ashutosh12

Email: ashutoshpandeyies@gmail.com

## 📜 License
This project is licensed under the MIT License – see the LICENSE file for details.

## ⚡ amitos | Built for Industry 4.0 | GPU-Powered | AI on the Edge | Secured by Debian
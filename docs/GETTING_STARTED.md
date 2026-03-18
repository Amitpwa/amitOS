# Getting Started with amitOS

This guide walks you through installing and running **amitOS** for the first time.

---

## Prerequisites

Before you begin, ensure you have:

| Requirement | Minimum | Notes |
|---|---|---|
| CPU | x86_64 or ARMv8 | 64-bit required |
| RAM | 2 GB | 8 GB+ recommended for AI workloads |
| Storage | 8 GB | SSD strongly recommended |
| Network | Ethernet or Wi-Fi | Ethernet preferred for industrial use |
| GPU *(optional)* | NVIDIA with CUDA 11+ | Required for GPU-accelerated AI |
| Host OS | Linux / Windows / macOS | For building/flashing the image |

---

## Installation

### Option 1: Clone & Install (Development / Evaluation)

```bash
# Clone the repository
git clone https://github.com/Amitpwa/amitOS.git
cd amitOS

# Run the installer (requires sudo)
sudo bash install.sh
```

### Option 2: Flash a Pre-built Image *(coming soon)*

Pre-built ISO images will be available on the [Releases](https://github.com/Amitpwa/amitOS/releases) page.

```bash
# Flash to USB (replace /dev/sdX with your USB device)
sudo dd if=amitOS-v0.2.0.iso of=/dev/sdX bs=4M status=progress && sync
```

---

## First Boot

After installation, the system will reboot into amitOS. You will be greeted with a minimal CLI.

### 1. Verify Core Services

```bash
# Check OPC UA server status
systemctl status opcua-server

# Check networking
systemctl status NetworkManager
ip addr show

# Check Nginx reverse proxy
systemctl status nginx
```

### 2. Configure Networking

amitOS uses **Netplan** for network configuration. Edit the config file:

```bash
sudo nano /etc/netplan/01-amitos.yaml
```

Example configuration (static IP):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

Apply the configuration:

```bash
sudo netplan apply
```

> 📖 For advanced networking setup, see [NETWORKING.md](NETWORKING.md)

### 3. Verify OPC UA Connectivity

```bash
# Test OPC UA server is reachable
curl -k opc.tcp://localhost:4840

# View OPC UA server logs
journalctl -u opcua-server -f
```

### 4. Verify AI / GPU Runtime

```bash
# Check CUDA availability
nvidia-smi

# Test Python AI stack
python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())"
python3 -c "import onnxruntime; print('ONNX providers:', onnxruntime.get_available_providers())"
```

---

## Quick Adapter Setup

Enable and configure an adapter (e.g., Modbus):

```bash
# Enable the Modbus adapter
sudo systemctl enable modbus-adapter
sudo systemctl start modbus-adapter

# Edit adapter configuration
sudo nano /etc/amitos/adapters/modbus.yaml
```

> 📖 For full adapter documentation, see [ADAPTERS.md](ADAPTERS.md)

---

## Directory Structure

```
/etc/amitos/
├── adapters/          # Adapter configuration files
│   ├── modbus.yaml
│   ├── mqtt.yaml
│   ├── siemens-s7.yaml
│   ├── bacnet.yaml
│   └── rest-bridge.yaml
├── opcua/             # OPC UA server configuration
│   └── server.xml
└── nginx/             # Nginx site configurations

/opt/amitos/
├── adapters/          # Adapter binaries / Python modules
├── ai/                # AI runtime helpers and examples
└── scripts/           # System utility scripts

/var/log/amitos/       # amitOS service logs
```

---

## Common Issues

| Issue | Solution |
|---|---|
| OPC UA server not starting | Check port 4840 is not blocked: `sudo ufw allow 4840/tcp` |
| CUDA not detected | Verify NVIDIA drivers: `nvidia-smi`. Reinstall if missing |
| Netplan config error | Run `sudo netplan try` to validate before applying |
| Adapter not connecting | Check adapter logs: `journalctl -u <adapter-name> -f` |

---

## Next Steps

- 🚀 **[amitOS in Action: Hands-On Quickstart](AMITOS_IN_ACTION.md)** — Try out 5 practical features of amitOS today!
- 📖 [Architecture Overview](ARCHITECTURE.md)
- 🔌 [Adapter Framework Guide](ADAPTERS.md)
- 🤖 [AI & GPU Setup](AI_GPU.md)
- 🌐 [Networking Guide](NETWORKING.md)
- 🗺️ [Roadmap](ROADMAP.md)

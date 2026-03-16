# amitOS Kernel Guide

This document covers the amitOS custom kernel configuration, build process, and runtime tuning for industrial edge computing.

---

## Kernel Strategy

amitOS uses the **standard Debian kernel** with a **custom configuration fragment** applied on top. This approach:

- ✅ Keeps full compatibility with Debian security updates
- ✅ Maintains NVIDIA driver compatibility
- ✅ Adds industrial-specific optimizations
- ✅ Minimizes maintenance burden

> **DAR Decision #2**: Standard Debian Kernel + PREEMPT. See [DAR.md](DAR.md) for rationale.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Debian Default .config              │
│          (6.1.x LTS — stable, tested)           │
├─────────────────────────────────────────────────┤
│         + config-amitos.fragment                 │
│     (Industrial tuning, containers, GPU)        │
├─────────────────────────────────────────────────┤
│        = amitOS Custom Kernel .deb               │
│     linux-image-*-amitos / linux-headers-*       │
└─────────────────────────────────────────────────┘
```

---

## Config Fragment Overview

The file `kernel/config-amitos.fragment` modifies 15 areas of the kernel:

| # | Area | What It Does |
|---|---|---|
| 1 | **Preemption** | Enables `CONFIG_PREEMPT` for soft real-time (500ms–1s OPC UA polling) |
| 2 | **Timers** | 1000Hz tick + high-res timers for precise scheduling |
| 3 | **Cgroups** | Full cgroup v2 support for Docker containers |
| 4 | **Namespaces** | PID, NET, USER, IPC, UTS — required for containers |
| 5 | **OverlayFS** | Docker image layer filesystem |
| 6 | **Networking** | Bridge, VXLAN, VETH, CAN bus, VLAN, nftables, BBR |
| 7 | **Industrial I/O** | IIO subsystem for ADC, temperature, pressure, IMU sensors |
| 8 | **Serial/USB** | FTDI, PL2303, CP210x, CH341 USB-serial drivers + RS-485 |
| 9 | **SPI/I2C/GPIO** | Hardware bus access for edge devices |
| 10 | **Watchdog** | Hardware + software watchdog for industrial reliability |
| 11 | **GPU/DRM** | NVIDIA out-of-tree driver infrastructure + IOMMU |
| 12 | **Security** | AppArmor, YAMA, stack protector, ASLR, audit |
| 13 | **Disabled** | Sound, Bluetooth, NFC, joystick, DVB — not needed on edge |
| 14 | **Power** | CPU frequency governors, Intel P-State, thermal management |
| 15 | **Misc** | BPF, kexec/crash dump, dm-crypt, FUSE, PSI |

---

## Building a Custom Kernel

### Prerequisites

```bash
sudo apt install build-essential fakeroot dpkg-dev libncurses-dev \
    flex bison libssl-dev libelf-dev bc rsync cpio kmod dwarves
```

### Build

```bash
# Build for current architecture (amd64)
sudo ./kernel/build-kernel.sh

# Build for ARM64 (cross-compile)
sudo ./kernel/build-kernel.sh --arch arm64

# Build with menuconfig for manual review
sudo ./kernel/build-kernel.sh --menuconfig

# Clean previous build and rebuild
sudo ./kernel/build-kernel.sh --clean
```

Or use the Makefile:

```bash
make kernel
```

### Output

Kernel packages are placed in `build/output/`:

```
build/output/
├── linux-image-6.1.x-amitos-YYYYMMDD_amd64.deb
└── linux-headers-6.1.x-amitos-YYYYMMDD_amd64.deb
```

### Install

```bash
sudo dpkg -i build/output/linux-image-*.deb
sudo dpkg -i build/output/linux-headers-*.deb
sudo update-grub
sudo reboot
```

---

## Runtime Kernel Tuning

### sysctl Parameters

The file `kernel/sysctl-amitos.conf` is installed to `/etc/sysctl.d/99-amitos.conf`.

Key tuning areas:

| Area | Parameters | Purpose |
|---|---|---|
| **Network** | ip_forward, bridge-nf-call, conntrack, TCP tuning | Docker + industrial networking |
| **Security** | SYN cookies, no redirects, no source routing, dmesg_restrict | Attack surface reduction |
| **Real-time** | sched_rt_runtime, sched_migration_cost | Industrial scheduling latency |
| **Memory** | shmmax, file-max, swappiness=10, dirty ratios | Edge device optimization |
| **Stability** | panic=10, nmi_watchdog, hung_task_timeout | Auto-recovery on failure |

Apply manually:

```bash
sudo sysctl --system
```

### Module Loading

The file `kernel/modules-load.conf` is installed to `/etc/modules-load.d/amitos.conf`.

Auto-loaded modules:
- `overlay`, `br_netfilter` — Docker
- `nf_tables` — nftables firewall

Hardware-specific modules are commented out by default. Uncomment as needed:
- CAN bus: `can`, `can-raw`, `vcan`
- Serial: `ftdi_sio`, `cp210x`, `ch341`
- Hardware: `i2c-dev`, `spi-dev`, `gpio-cdev`

---

## Upgrading to RT-PREEMPT

If sub-1ms hard real-time is required (e.g., motion control, EtherCAT):

1. **Open a DAR change request** (see [DAR.md](DAR.md) — Decision Change Protocol)
2. Download the RT-PREEMPT patch for your kernel version
3. Modify `config-amitos.fragment`:

```
# Replace:
CONFIG_PREEMPT=y
# With:
CONFIG_PREEMPT_RT=y
CONFIG_PREEMPT_RT_FULL=y
```

4. Rebuild the kernel:

```bash
sudo ./kernel/build-kernel.sh --clean
```

> ⚠️ **Note**: RT-PREEMPT may affect NVIDIA driver compatibility. Test thoroughly.

---

## Verifying Kernel Configuration

After booting the amitOS kernel:

```bash
# Check kernel version
uname -r

# Verify PREEMPT is enabled
grep PREEMPT /proc/version

# Check loaded modules
lsmod | grep -E 'overlay|br_netfilter|nf_tables'

# Check sysctl values
sysctl net.ipv4.ip_forward
sysctl kernel.sched_rt_runtime_us

# Check CAN bus (if enabled)
ip link show type can
```

---

## File Locations

| File | Installed To | Purpose |
|---|---|---|
| `kernel/config-amitos.fragment` | *(build-time only)* | Kernel config delta |
| `kernel/build-kernel.sh` | *(build-time only)* | Automated kernel builder |
| `kernel/sysctl-amitos.conf` | `/etc/sysctl.d/99-amitos.conf` | Runtime kernel tuning |
| `kernel/modules-load.conf` | `/etc/modules-load.d/amitos.conf` | Boot-time module loading |

---

## Troubleshooting

| Issue | Solution |
|---|---|
| Kernel build fails | Check `build/kernel-build/build.log` for errors |
| NVIDIA driver won't load | Ensure kernel headers match: `apt install linux-headers-$(uname -r)` |
| High latency | Verify PREEMPT: `grep PREEMPT /proc/version` |
| CAN interface not visible | Load module: `sudo modprobe can` |
| sysctl errors at boot | Check `/etc/sysctl.d/99-amitos.conf` for unsupported parameters |

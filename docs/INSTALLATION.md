# amitOS Installation Guide

This guide covers how to install amitOS on physical hardware (x86_64 or ARM64) cleanly. 

Unlike standard applications, **amitOS is a full Operating System**. You have two main pathways to install it: building and flashing a bootable bare-metal image (the true OS way), or transforming an existing minimal Debian installation into an amitOS system (legacy/in-place method).

---

## Method 1: Bare-Metal OS Installation (Recommended for Edge Devices)

Use this method if you want to install amitOS onto an empty device (like an Industrial PC, Raspberry Pi, or unprovisioned x86 gateway). 

This approach builds a bootable `.img` file from scratch that contains the Debian Bookworm core bundled with the custom amitOS kernel, adapters, and frameworks. **You are building a complete Operating System.**

### Step 1: Build the OS Image
On your host building machine (can be Ubuntu, Debian, etc.), clone the project and install the prerequisites required to build OS images:

```bash
# Clone the repository
git clone https://github.com/Amitpwa/amitOS.git
cd amitOS

# Install OS building prerequisites
sudo apt update
sudo apt install -y debootstrap qemu-user-static binfmt-support dosfstools parted wget rsync
```

Next, use the `Makefile` to trigger the build system. This will bootstrap the Debian root filesystem and layer the amitOS configuration on top.

```bash
# Build the default x86_64 (amd64) raw OS image
make image

# (Optional) If you are building for an ARM64 edge node like a Jetson or Pi:
sudo ./build/build-image.sh --arch arm64
```

*This process takes a few minutes. When finished, your bootable OS images will be in the `build/output/` directory (e.g., `build/output/amitOS-0.3.0-dev-amd64.img`).*

### Step 2: Flash to a USB / SD Card / eMMC
You now need to write the raw `.img` file to your target boot medium.

**Using the Command Line (Linux / macOS):**
```bash
# Find your USB drive (e.g., /dev/sdb)
lsblk 

# Write the OS directly to the block device.
# WARNING: This will erase all data on the target drive!
sudo dd if=build/output/amitOS-0.3.0-dev-amd64.img of=/dev/sdX bs=4M status=progress
sync
```

**Using GUI Tools (Windows / Mac / Linux):**
1. Download **[balenaEtcher](https://etcher.balena.io/)** or **[Rufus](https://rufus.ie/)**.
2. Select the `.img` file generated in the `build/output/` folder.
3. Select your USB drive or SD Card.
4. Click **Flash**.

### Step 3: Boot the System
1. Insert the booted USB/SD Card into your target hardware.
2. Turn on the device and access the BIOS/UEFI boot menu.
3. Select the flashed drive to boot from.
4. amitOS will boot immediately as the primary Operating System.
   - **Default System Username:** `amitos`
   - **Default System Password:** `amitos`
   - **Root Password:** `amitos`

*(If you chose to flash to a USB drive but want the OS permanently installed on the internal hard drive, you can run the same `dd` command from inside the live amitOS environment targeting the internal `/dev/nvme0n1` or `/dev/sda` drive).*

---

## Method 2: The In-Place Transformation (For Existing Hardware)

If you already have a physical server or VM running a fresh copy of **Debian 12 (Bookworm)** and you don't want to wipe the partition table, you can convert the running system into amitOS.

### Step 1: Clone the Repo on the Target Machine
Log into your Debian machine (SSH or physical console) and fetch the installer:

```bash
git clone https://github.com/Amitpwa/amitOS.git
cd amitOS
```

### Step 2: Run the Installer
Launch the installation script. You can use the GUI wizard or the raw CLI:

**Interactive GUI Wizard:**
```bash
sudo ./gui-installer.sh
```

**Headless CLI Install (Useful for remote SSH):**
```bash
sudo bash install.sh
```

**Optional Install Flags:**
- `--desktop` : Installs a lightweight XFCE4 desktop alongside the edge OS.
- `--skip-docker` : Skips installing the Docker container engine (saves space).
- `--skip-nvidia` : Skips adding the CUDA repositories for AI vision pipelines.

### Step 3: Reboot
```bash
sudo reboot
```
Your machine will wake up as an amitOS edge node, with all adapters, systemd services, and customized system configurations ready.

---

## Post-Installation Next Steps

Once the OS is booted natively on your system, verify its services:
1. Verify system architecture and version: `amitos-info`
2. Run a full health diagnostic: `amitos-check --full`
3. View the [Networking Guide](NETWORKING.md) to set a static IP or configure the firewall.

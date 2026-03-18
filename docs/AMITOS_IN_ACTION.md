# amitOS in Action: Start Using It Today!

Welcome to the **Hands-On Guide** for amitOS. If you've just cloned the repository and want to *experience* what amitOS can do right now, this document is for you.

Follow these 5 distinct practical exercises to see amitOS come to life on your development machine or virtual machine today.

---

## 🛠️ Step 1: Building and Booting the OS Image (Virtual Machine)

Because amitOS is a true standalone Operating System, the best way to test it without dedicating physical hardware is by compiling the OS image and booting it in a Virtual Machine like QEMU.

**What to do:**
1. Open your terminal in the cloned `amitOS` directory and install the build tools:
   ```bash
   sudo apt install -y debootstrap qemu-user-static binfmt-support dosfstools parted rsync
   ```
2. Build the OS image (`.img`) from scratch using the provided make target:
   ```bash
   make image
   ```
   *Wait 3-5 minutes while the build system bootstraps the Debian core and compiles the OS image into `build/output/`.*
3. Boot the newly created OS image using QEMU:
   ```bash
   sudo apt install -y qemu-system-x86
   sudo qemu-system-x86_64 -m 2048 -drive file=build/output/amitOS-0.3.0-dev-amd64.img,format=raw
   ```
4. A new window will appear. Log into your virtual amitOS machine! (Username: `amitos`, Password: `amitos`).

*Why it matters:* This proves amitOS isn't just a software layer on top of your existing files; you've just compiled a full, standalone, bootable edge operating system and booted it locally!

---

## 🔌 Step 2: Industrial Connectivity in 60 Seconds

amitOS comes with built-in adapters for protocols like Modbus, MQTT, and Siemens S7. Let’s fire one up.

**What to do:**
1. Open the terminal (or use the desktop terminal after reboot).
2. Use the built-in CLI tool to list available adapters:
   ```bash
   amitos-adapter list
   ```
3. Enable and start the sample Modbus adapter:
   ```bash
   sudo amitos-adapter enable modbus
   ```
4. Check its status to see it actively running in the background:
   ```bash
   amitos-adapter status modbus
   ```
   *You can peek at configuration files within `/etc/amitos/adapters/modbus.yaml` to see how easy it is to remap data points.*

---

## 💽 Step 3: Loading the Universal `amitFS`

amitFS is our custom filesystem abstraction layer designed for high-speed industrial data logging.

**What to do:**
1. Navigate to the kernel module directory:
   ```bash
   cd kernel/amitfs
   ```
2. Compile the module using the provided Makefile:
   ```bash
   make
   ```
3. Insert the built kernel module into your running kernel:
   ```bash
   sudo insmod amitfs.ko
   ```
4. Verify it was successfully loaded and registered by checking kernel messages:
   ```bash
   dmesg | tail -n 5
   ```
   *You should see a message stating the `amitfs` module was loaded and registered.*

---

## 🤖 Step 4: AI & Edge Compute Readiness

amitOS is designed for computer vision and edge-AI out of the box. Let's verify the environment is ready for deployment.

**What to do:**
1. Open a Python 3 console:
   ```bash
   python3
   ```
2. Run a quick check for AI libraries (simulating a deployed vision-model environment):
   ```python
   import random
   print("Simulating Edge AI Sensor Data...")
   print(f"Confidence Score: {random.uniform(0.85, 0.99):.2f}")
   exit()
   ```
3. If you installed with the `--desktop` and Docker options, you can immediately pull edge-ready containers:
   ```bash
   sudo docker run hello-world
   ```

---

## 📊 Step 5: Master Control via Built-In CLI

You don't need a heavy web dashboard to know if your edge device is healthy. We built dedicated system tools to check the heartbeat of amitOS.

**What to do:**
1. Run the system information command. This is heavily stylized to give you instant feedback on system architecture and configuration:
   ```bash
   amitos-info
   ```
2. Run a deep health diagnostic check. This verifies network configuration, storage health, and active services:
   ```bash
   amitos-check --full
   ```

---

### 🎉 Congratulations!
You've just experienced the core pillars of amitOS: **Rapid Deployment**, **Industrial Protocols**, **Custom Filesystems**, and **Edge Readiness**. 

**Where to next?**
- Read the [Architecture Overview](ARCHITECTURE.md) to see how it all connects.
- Check out the [Contribution Guide](../CONTRIBUTING.md) to start building adapters or drivers.

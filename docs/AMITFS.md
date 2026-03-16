# amitFS (amitOS Native Filesystem Framework)

`amitFS` is the unified, high-performance filesystem framework designed specifically for **amitOS**. 

## Purpose
Rather than just being a single format, **amitFS** acts as an intelligent, universal abstraction layer that **natively supports all major filesystems** (BTRFS, XFS, NTFS3, EXFAT, FAT32, F2FS, EXT4) while providing specialized capabilities for **Industrial Edge scenarios**.

When you format a drive or use storage in amitOS, you are using the **amitFS** unified framework. The framework ensures:
1. **Universal Compatibility:** Seamlessly read/write to Windows (NTFS/FAT), Linux (EXT4/BTRFS/XFS), and flash-optimized (F2FS/EXFAT) drives without manual mounting configuration.
2. **High-speed Time-Series Storage:** Optimized contiguous disk allocation routines for industrial sensors (OPC UA data logging).
3. **Flash Wear-leveling:** Built-in safeguards for deploying on cheap eMMC and SD cards used in industrial gateways.
4. **Atomic Edge Updates:** Integration with our OTA update system to allow fast snapshots of running states across any underlying compatible filesystem (like BTRFS).

## Kernel Module Status
The core of amitFS is being developed as a Linux Kernel Module. The current module source can be found in `kernel/amitfs/`.
It registers itself with the Linux VFS (Virtual File System) using the magic bytes `0x414D4954` ("AMIT"). It serves as the gateway to the underlying diverse filesystems.

## Building amitFS Core (Standalone)
During active development, you can build the kernel module independently:
```bash
cd kernel/amitfs
make
sudo insmod amitfs.ko
```

## Roadmap
- [x] Phase 1: Universal VFS Registration Skeleton
- [x] Phase 2: Kernel config integration for ALL filesystems (EXT4, NTFS, BTRFS, XFS, etc.)
- [ ] Phase 3: Auto-mounting intelligence & Block device layout tool (`mkfs.amitfs`)
- [ ] Phase 4: Time-Series optimizations wrapper

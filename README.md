# Eir — Custom NixOS Recovery USB

**Eir** (named after the Norse goddess associated with medical skill and healing) is a custom, reproducible NixOS-based live recovery USB image built using Nix Flakes on NixOS 26.05.

It is designed to replace generic live Linux ISOs (Arch, Mint, Ubuntu) with a tailorable, deterministic rescue image that can be built and updated reproducibly. It will also include the users personal terminal setup for familiarity.

---

## Project Structure

```
.
├── flake.nix          # Entrypoint defining dependencies and nixosConfigurations.recovery
├── flake.lock         # Pinned Git commits for dependencies (nixpkgs 26.05)
└── configuration.nix  # NixOS module configuring recovery packages, tools, and services
```

---

## Build & Usage Quick Reference

### Evaluating & Building the ISO Image

To evaluate and build the recovery ISO using the flake:

```bash
nix build .#nixosConfigurations.recovery.config.system.build.isoImage
```

Upon completion, a `./result` symlink will point to the build output in `/nix/store`, containing the `.iso` file under `./result/iso/`.

### Updating Dependencies

To update `nixpkgs` to the latest commit on the `nixos-26.05` release branch or dotfiles input:

```bash
nix flake update
```

To rollback an update:

```bash
git checkout flake.lock
```

---

## Flashing & Persistence Setup

### 1. Identify Target USB Drive
Insert target USB drive (minimum 8GB) and list block devices:

```bash
lsblk
```
*(Verify drive name, e.g. `/dev/sdb`. Double check to avoid overwriting primary system drives!)*

### 2. Flash ISO Image to USB
Unmount any existing partitions on the target USB drive, then flash the built ISO to `/dev/sdX`:

```bash
# Unmount any active partitions on target drive
sudo umount /dev/sdX* 2>/dev/null || true

# Locate built ISO and write to USB
ISO_FILE=$(ls ./result/iso/*.iso)
sudo dd if="$ISO_FILE" of=/dev/sdX bs=4M status=progress conv=fsync

# Force kernel to re-read partition table
sudo partprobe /dev/sdX
```

### 3. Create & Format Persistence Partition
The ISO occupies ~2.5GB. Create a partition in the remaining unallocated space for persistent data:

```bash
# Open partition table
sudo fdisk /dev/sdX

# In fdisk:
# 1. Type 'n' for new partition
# 2. Select default partition number (3) and default start/end sectors
# 3. Type 'w' to write partition table and exit
```

Re-read partition table and format as `ext4` with the label `EIR_PERSIST`:

```bash
sudo partprobe /dev/sdX
sudo mkfs.ext4 -L EIR_PERSIST /dev/sdX3
```

*(Note: If your device uses NVMe/SD-card naming, the partition will be `/dev/nvme0n1p3` or `/dev/sdX3`)*

### 4. Booting & Login
- Boot target computer in UEFI mode and select the USB drive.
- Autologin enters user `eir` into `i3` desktop manager.
- Default credentials: user `eir`, password `eiR1!`.
- SSH service is active on boot (`ssh eir@<ip>`).

---

## Technical Concept Notes

For a detailed conceptual breakdown of Nix primitives (Derivations, Nix Store, Flakes, Module System, and Image Building), see:
[Nix Foundations Reference](.pi/notes.local/nix-foundations-reference.md)

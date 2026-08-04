# Eir — Custom NixOS Recovery USB

**Eir** (named after the Norse goddess associated with medical skill and healing) is a custom, reproducible NixOS-based live recovery USB image built using Nix Flakes on NixOS 26.05.

It replaces generic live Linux ISOs (Arch, Mint, Ubuntu) with a tailorable, deterministic rescue image containing customized rescue tooling, familiar dotfiles/shell configuration, an i3 tiling desktop, and persistent storage support.

---

## Project Structure

```
.
├── flake.nix              # Entrypoint defining dependencies and nixosConfigurations.recovery
├── flake.lock             # Pinned Git commits for dependencies (nixpkgs 26.05)
├── configuration.nix      # Root NixOS configuration module
├── modules/
│   ├── core.nix           # Base system settings, bootloader branding, firmware, locale
│   ├── desktop.nix        # X11, i3-gaps, Polybar, Rofi, Picom, LightDM autologin
│   ├── programs.nix       # Shell (zsh/p10k), tmux, Neovim, WezTerm, Firefox, dotfiles integration
│   └── recovery.nix       # Storage, partition, diagnostic, and network recovery toolset
├── config/
│   ├── i3/config          # i3 window manager configuration
│   ├── polybar/config.ini # Polybar status bar configuration (Neofusion palette)
│   └── rofi/config.rasi   # Rofi launcher & power menu theme
└── scripts/
    ├── process-dotfiles.sh # Nix build helper processing user dotfiles into /etc/skel
    ├── eir-persistence.sh  # Boot oneshot script mounting EIR_PERSIST overlay
    └── rofi-power-menu.sh  # Interactive power options menu for Polybar/i3
```

---

## Build & Usage Quick Reference

### Evaluating & Building the ISO Image

To evaluate and build the recovery ISO using the flake:

```bash
nix build .#nixosConfigurations.recovery.config.system.build.isoImage
```

Upon completion, a `./result` symlink will point to the build output in `/nix/store`, containing the `.iso` file under `./result/iso/`.

### Updating Dotfiles or System Packages

To update dotfiles from GitHub or bump `nixpkgs` to the latest commit on `nixos-26.05`:

```bash
# Update dotfiles input specifically
nix flake update dotfiles

# Or update all flake inputs
nix flake update

# Rebuild the ISO image
nix build .#nixosConfigurations.recovery.config.system.build.isoImage
```

To rollback flake input updates:

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
*(Verify drive name, e.g. `/dev/sdX`. Double check to avoid overwriting primary system drives!)*

### 2. Flash ISO Image to USB
Unmount any existing partitions on the target USB drive, then flash the built ISO:

```bash
# Unmount active partitions on target drive
sudo umount /dev/sdX* 2>/dev/null || true

# Locate built ISO and write to USB
ISO_FILE=$(ls ./result/iso/*.iso)
sudo dd if="$ISO_FILE" of=/dev/sdX bs=4M status=progress conv=fsync

# Force kernel to re-read partition table
sudo partprobe /dev/sdX
```

### 3. Create & Format Persistence Partition
The ISO occupies ~2.5GB. Create a partition in the remaining space for persistent data:

```bash
# Open partition table
sudo fdisk /dev/sdX

# In fdisk:
# 1. Type 'n' for new partition
# 2. Select default partition number (3) and default start/end sectors
# 3. Type 'w' to write partition table and exit
```

Re-read partition table and format partition 3 as `ext4` with label `EIR_PERSIST`:

```bash
sudo partprobe /dev/sdX
sudo mkfs.ext4 -L EIR_PERSIST /dev/sdX3
```

*(Note: If device uses NVMe/SD-card naming, partition will be `/dev/nvme0n1p3` or `/dev/mmcblk0p3`)*

---

## Environment & Keybindings

### Boot & Access
- **Autologin:** Boots directly into i3 as user `eir`.
- **Default Credentials:** User `eir`, password `eiR1!`.
- **SSH Service:** Active on boot (`ssh eir@<ip>`), password authentication enabled.

### Desktop Shortcuts (i3 / Rofi / Polybar)
- **Mod Key:** `Alt` (`Mod1`)
- **Navigation:** `Alt` + `W`/`A`/`S`/`D` (Focus window), `Shift` + `Alt` + `W`/`A`/`S`/`D` (Move window)
- **Workspaces:** `Alt` + `1`..`4` (Switch), `Shift` + `Alt` + `!`..`$` (Move container)
- **Applications:**
  - `Shift` + `Alt` + `T` — Launch WezTerm
  - `Shift` + `Alt` + `F` — Launch Thunar File Manager
  - `Alt` + `Q` — Open Rofi Application Launcher
  - `Alt` + `E` — Window Switcher
  - `Shift` + `Alt` + `X` / `Super` + `X` — Kill active window
  - `Shift` + `Alt` + `E` (or Polybar `⏻` button) — Open Rofi Power Menu (Shutdown, Reboot, Suspend, Exit)

---

## Included Recovery Toolset

- **Partitioning & Filesystems:** `parted`, `gptfdisk`, `gparted`, `e2fsprogs`, `dosfstools`, `ntfs3g`, `btrfs-progs`, `xfsprogs`, `cryptsetup`
- **Data Recovery & Storage Diagnostics:** `testdisk`, `ddrescue`, `smartmontools`, `nvme-cli`, `partclone`
- **Hardware & System Diagnostics:** `htop`, `pciutils`, `usbutils`, `lm_sensors`, `lsof`, `dmidecode`
- **Network & Packet Analysis:** `curl`, `rsync`, `tcpdump`, `termshark`, `wireshark`, `bind.dnsutils` (`dig`), `netcat-gnu`, `nmap`

---

## How Persistence Works

When the USB boots, `eir-persistence.service` automatically runs before user login:
1. Searches for a disk partition labeled `EIR_PERSIST`.
2. If found, bind-mounts persistent directories over `/home/eir` and `/etc/NetworkManager/system-connections`.
3. If booting for the first time on a freshly formatted `EIR_PERSIST` partition, initializes persistent `/home/eir` from base image dotfiles (`/etc/skel`).
4. If no `EIR_PERSIST` partition is present, runs entirely in volatile RAM (standard live ISO behavior).

---

## Official Documentation & References

For deeper technical reference on NixOS, flakes, and ISO generation:
- [NixOS Manual (26.05)](https://nixos.org/manual/nixos/stable/)
- [Nix Reference Manual](https://nixos.org/manual/nix/stable/)
- [Building Bootable ISO Images (nix.dev)](https://nix.dev/tutorials/nixos/building-bootable-iso-image.html)

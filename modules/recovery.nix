{ pkgs, ... }:

{
  # System packages & recovery toolset
  environment.systemPackages = with pkgs; [
    # Partitioning & Filesystems
    parted
    gptfdisk
    e2fsprogs
    dosfstools
    ntfs3g
    btrfs-progs
    xfsprogs
    zfs
    cryptsetup
    gparted
    partclone

    # Data Recovery & Storage Diagnostics
    testdisk
    ddrescue
    smartmontools
    nvme-cli

    # Hardware & System Diagnostics
    pciutils
    usbutils
    lsof
    lshw
    dmidecode
    ethtool
    lm_sensors
    htop
    btop

    # Network & Packet Analysis
    curl
    wget
    rsync
    nmap
    netcat-gnu
    iperf3
    bind.dnsutils
    tcpdump
    termshark
    wireshark
  ];
}

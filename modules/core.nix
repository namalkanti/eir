{ pkgs, ... }:

{
  # Boot settings & branding
  boot.zfs.forceImportRoot = false;
  isoImage.volumeID = "eir-recovery";
  isoImage.edition = "eir";
  isoImage.prependToMenuLabel = "Eir Recovery — ";
  isoImage.appendToMenuLabel = "";

  # Allow unfree packages (required for non-free firmware blobs e.g. Broadcom)
  nixpkgs.config.allowUnfree = true;

  # Hardware / Firmware support
  hardware.enableAllFirmware = true;

  # Power Management (TLP detects laptop vs desktop dynamically)
  powerManagement.enable = true;
  services.tlp.enable = true;

  # PipeWire Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # SSH — password auth for recovery scenarios
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # NetworkManager
  networking.hostName = "eir-recovery";
  networking.networkmanager.enable = true;

  # User account & autologin
  users.users.eir = {
    isNormalUser = true;
    uid = 1000;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "eiR1!";
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "eir";
  };

  # Persistence support for USB partition labeled EIR_PERSIST
  systemd.services.eir-persistence = {
    description = "Eir Live USB Partition Persistence";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" "network-manager.service" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ util-linux coreutils ];
    script = builtins.readFile ../scripts/eir-persistence.sh;
  };
}

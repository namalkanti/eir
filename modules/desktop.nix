{ pkgs, dotfiles, ... }:

let
  # Power menu launcher using Rofi
  rofiPowerMenu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = with pkgs; [ rofi systemd i3 ];
    text = builtins.readFile ../scripts/rofi-power-menu.sh;
  };

  # Resolve symlinks + process dotfiles for the ISO
  resolvedDotfiles = pkgs.runCommand "dotfiles-resolved" {
    fzf_bin = "${pkgs.fzf}/bin/fzf";
    inherit dotfiles;
  } (builtins.readFile ../scripts/process-dotfiles.sh);

  nixWallpaper = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

  i3Config = builtins.replaceStrings [ "@feh@" "@nixWallpaper@" ] [ "${pkgs.feh}" "${nixWallpaper}" ] (builtins.readFile ../config/i3/config);
  polybarConfig = builtins.readFile ../config/polybar/config.ini;
  rofiConfig = builtins.readFile ../config/rofi/config.rasi;
  dunstConfig = builtins.readFile ../config/dunst/dunstrc;

  # Offline Surfingkeys extension CRX package from Chrome Web Store
  surfingkeysCrx = pkgs.fetchurl {
    name = "surfingkeys-1.18.0.crx";
    url = "https://clients2.google.com/service/update2/crx?response=redirect&os=linux&arch=x86-64&os_arch=x86-64&nacl_arch=x86-64&prod=chromecx&prodversion=120.0&acceptformat=crx2,crx3&x=id%3Dgfbliohnnapiefjpjlpjnehglfpaknnc%26uc";
    sha256 = "0zf6zzyvz9hsd072jvhsgzffa6g4xbhrx838jfq18ixack0xyc91";
  };
in

{
  # Window Manager configuration
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.options = "caps:swapescape";
    windowManager.i3.enable = true;
  };

  # Fonts — MesloLGS NF required by wezterm config and powerlevel10k
  fonts.fontconfig.enable = true;
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  # Default browser for xdg-open
  xdg.mime.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
  };

  # Desktop Utilities & GUI apps
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    wezterm
    brave
    lf
    fzf
    ripgrep
    git
    i3
    polybar
    rofi
    picom
    feh
    rofiPowerMenu
    thunar
    brightnessctl
    pavucontrol
    dunst
    i3lock
    fastfetch
    papirus-icon-theme
  ];

  # Systemd service to sync /etc/skel into /home/eir before display manager starts
  systemd.services.eir-init-home = {
    description = "Initialize eir home directory from /etc/skel";
    wantedBy = [ "multi-user.target" ];
    before = [ "display-manager.service" ];
    after = [ "eir-persistence.service" "etc.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ rsync coreutils ];
    script = ''
      mkdir -p /home/eir
      rsync -aL /etc/skel/ /home/eir/
      chown -R eir:users /home/eir
    '';
  };

  # Populate skeleton directory so /etc/skel contains all dotfiles & configs
  environment.etc = {
    "skel/.zshrc".source = "${resolvedDotfiles}/.zshrc";
    "skel/.bashrc".source = "${resolvedDotfiles}/.bashrc";
    "skel/.bash_aliases".source = "${resolvedDotfiles}/.bash_aliases";
    "skel/.p10k.zsh".source = "${resolvedDotfiles}/.p10k.zsh";
    "skel/.tmux.conf".source = "${resolvedDotfiles}/.tmux.conf";
    "skel/.vimrc".source = "${resolvedDotfiles}/.vimrc";
    "skel/.vim".source = "${resolvedDotfiles}/.vim";
    "skel/.claude".source = "${resolvedDotfiles}/.claude";
    "skel/.config/wezterm".source = "${resolvedDotfiles}/wezterm";
    "skel/.config/lf".source = "${resolvedDotfiles}/lf";
    "skel/.config/surfingkeys".source = "${resolvedDotfiles}/surfingkeys";
    "skel/.config/i3/config".text = i3Config;
    "skel/.config/polybar/config.ini".text = polybarConfig;
    "skel/.config/rofi/config.rasi".text = rofiConfig;
    "skel/.config/dunst/dunstrc".text = dunstConfig;

    # Enterprise Policy to force-install Surfingkeys extension
    "brave/policies/managed/extensions.json".text = builtins.toJSON {
      ExtensionSettings = {
        "gfbliohnnapiefjpjlpjnehglfpaknnc" = {
          installation_mode = "force_installed";
          update_url = "https://clients2.google.com/service/update2/crx";
        };
      };
    };

    # Offline external extension definition for Brave and Chromium
    "brave/extensions/gfbliohnnapiefjpjlpjnehglfpaknnc.json".text = builtins.toJSON {
      external_crx = "${surfingkeysCrx}";
      external_version = "1.18.0";
    };
    "chromium/extensions/gfbliohnnapiefjpjlpjnehglfpaknnc.json".text = builtins.toJSON {
      external_crx = "${surfingkeysCrx}";
      external_version = "1.18.0";
    };
  };
}

{ pkgs, dotfiles, lib, ... }:

let
  # powerlevel10k structured for oh-my-zsh's custom themes directory
  p10kCustom = pkgs.runCommand "p10k-ohmyzsh-custom" {} ''
    mkdir -p $out/themes
    ln -s ${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k $out/themes/powerlevel10k
  '';

  # Power menu launcher using Rofi
  rofiPowerMenu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = with pkgs; [ rofi systemd i3 ];
    text = ''
      chosen=$(printf "Shutdown\nReboot\nSuspend\nExit i3" | rofi -dmenu -i -p "Power")
      case "$chosen" in
        Shutdown) systemctl poweroff ;;
        Reboot) systemctl reboot ;;
        Suspend) systemctl suspend ;;
        "Exit i3") i3-msg exit ;;
      esac
    '';
  };

  # Resolve symlinks + process dotfiles for the ISO
  resolvedDotfiles = pkgs.runCommand "dotfiles-resolved" {} ''
    mkdir -p $out

    # Shell
    cp -rL ${dotfiles}/.zshrc          $out/.zshrc
    cp -rL ${dotfiles}/.bashrc         $out/.bashrc
    cp -rL ${dotfiles}/.bash_aliases   $out/.bash_aliases
    cp -rL ${dotfiles}/.p10k.zsh       $out/.p10k.zsh

    # Strip oh-my-zsh self-management lines — NixOS handles these
    sed -i '/^export ZSH=/d'                $out/.zshrc
    sed -i '/^source \$ZSH\/oh-my-zsh.sh/d' $out/.zshrc

    # tmux — strip tpm plugin declarations, run line, and default-shell; NixOS manages plugins and shell
    cp -rL ${dotfiles}/.tmux.conf $out/.tmux.conf
    sed -i '/set -g @plugin/d'                         $out/.tmux.conf
    sed -i "/run '~\/.tmux\/plugins\/tpm\/tpm'/d"      $out/.tmux.conf
    sed -i '/set-option -g default-shell/d'            $out/.tmux.conf

    # neovim — strip vim-plug block and patch fzf path; NixOS manages plugins
    cp -rL ${dotfiles}/.vimrc $out/.vimrc
    sed -i '/^call plug#begin/,/^call plug#end/d' $out/.vimrc
    sed -i "s|/bin/fzf|${pkgs.fzf}/bin/fzf|g"    $out/.vimrc
    cp -rL ${dotfiles}/.vim $out/.vim

    # Editor / terminal / file manager configs
    cp -rL ${dotfiles}/.config/wezterm         $out/wezterm
    chmod u+w $out/wezterm
    sed -i "s/MesloLGS NF/MesloLGS Nerd Font/g" $out/wezterm/wezterm.lua
    cp -rL ${dotfiles}/.config/lf              $out/lf

    # Claude — resolve symlinks, inject AGENTS.md, fix CLAUDE.md reference
    cp -rL ${dotfiles}/.claude       $out/.claude
    chmod u+w $out/.claude
    cp -rL ${dotfiles}/.pi/agent/AGENTS.md $out/.claude/AGENTS.md
    echo '@~/.claude/AGENTS.md' > $out/.claude/CLAUDE.md
  '';

  nixWallpaper = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

  i3Config = ''
    font pango:MesloLGS Nerd Font 10
    floating_modifier Mod1

    # WASD focus (Alt + w/a/s/d)
    bindsym Mod1+a focus left
    bindsym Mod1+s focus down
    bindsym Mod1+w focus up
    bindsym Mod1+d focus right

    # WASD move (Shift + Alt + w/a/s/d)
    bindsym Shift+Mod1+a move left
    bindsym Shift+Mod1+s move down
    bindsym Shift+Mod1+w move up
    bindsym Shift+Mod1+d move right

    # Cycle focus (Alt + Tab / Shift + Alt + Tab)
    bindsym Mod1+Tab focus next
    bindsym Shift+Mod1+Tab focus prev

    # Workspaces
    bindsym Mod1+1 workspace number 1
    bindsym Mod1+2 workspace number 2
    bindsym Mod1+3 workspace number 3
    bindsym Mod1+4 workspace number 4

    # Move container to workspace
    bindsym Shift+Mod1+1 move container to workspace number 1
    bindsym Shift+Mod1+2 move container to workspace number 2
    bindsym Shift+Mod1+3 move container to workspace number 3
    bindsym Shift+Mod1+4 move container to workspace number 4

    # Application launches
    bindsym Shift+Mod1+t exec wezterm
    bindsym Shift+Mod1+f exec thunar
    bindsym Mod1+q exec "rofi -show drun"
    bindsym Mod1+e exec "rofi -show window"
    bindsym Shift+Mod1+e exec rofi-power-menu

    # Close window (Super + X or Shift + Alt + X)
    bindsym Mod4+x kill
    bindsym Shift+Mod1+x kill
    bindsym Shift+Mod1+c kill
    bindsym Shift+Mod1+r restart

    # Aesthetics & gaps
    gaps inner 8
    gaps outer 4
    default_border pixel 2
    default_floating_border pixel 2

    client.focused          #ea6847 #070f1c #e0d9c7 #ea6847 #ea6847
    client.focused_inactive #24273a #070f1c #8caaee #24273a #24273a
    client.unfocused        #1e1e2e #070f1c #a6adc8 #1e1e2e #1e1e2e
    client.urgent           #e78284 #070f1c #e0d9c7 #e78284 #e78284

    # Autostart
    exec_always --no-startup-id "pkill polybar; polybar main &"
    exec --no-startup-id picom
    exec --no-startup-id nm-applet
    exec --no-startup-id ${pkgs.feh}/bin/feh --bg-fill ${nixWallpaper}
  '';

  polybarConfig = ''
    [colors]
    background = #070f1c
    background-alt = #1e1e2e
    foreground = #e0d9c7
    primary = #ea6847
    secondary = #5db2f8
    alert = #e78284
    disabled = #6c7086

    [bar/main]
    width = 100%
    height = 24pt
    radius = 0

    background = ''${colors.background}
    foreground = ''${colors.foreground}

    line-size = 2pt
    border-size = 0pt

    padding-left = 1
    padding-right = 1

    module-margin = 1

    font-0 = "MesloLGS Nerd Font:size=10;2"

    modules-left = xworkspaces
    modules-center = date
    modules-right = memory cpu disk wlan battery powermenu tray

    cursor-click = pointer
    cursor-scroll = ns-resize

    enable-ipc = true

    [module/xworkspaces]
    type = internal/xworkspaces

    label-active = " %name% "
    label-active-background = ''${colors.primary}
    label-active-foreground = #070f1c
    label-active-padding = 0

    label-occupied = " %name% "
    label-occupied-background = ''${colors.background-alt}
    label-occupied-foreground = ''${colors.foreground}
    label-occupied-padding = 0

    label-urgent = " %name% "
    label-urgent-background = ''${colors.alert}
    label-urgent-padding = 0

    label-empty = " %name% "
    label-empty-foreground = ''${colors.disabled}
    label-empty-padding = 0

    [module/date]
    type = internal/date
    interval = 1
    date = %Y-%m-%d %I:%M %p
    label = %date%
    label-foreground = ''${colors.foreground}

    [module/cpu]
    type = internal/cpu
    interval = 2
    format-prefix = "CPU "
    format-prefix-foreground = ''${colors.secondary}
    label = %percentage%%

    [module/memory]
    type = internal/memory
    interval = 2
    format-prefix = "RAM "
    format-prefix-foreground = ''${colors.secondary}
    label = %percentage_used:2%%

    [module/disk]
    type = internal/fs
    interval = 25
    mount-0 = /
    label-mounted = %{F#5db2f8}/%{F-} %percentage_used%%

    [module/wlan]
    type = internal/network
    interface-type = wireless
    interval = 3.0
    format-connected = <label-connected>
    format-disconnected = <label-disconnected>
    label-connected = %{F#ea6847}WiFi%{F-} %essid% %local_ip%
    label-disconnected = %{F#6c7086}offline%{F-}

    [module/battery]
    type = internal/battery
    full-at = 99
    low-at = 10
    battery = BAT0
    adapter = ADP1
    poll-interval = 5

    [module/powermenu]
    type = custom/text
    label = " ⏻ "
    label-foreground = ''${colors.primary}
    click-left = rofi-power-menu

    [module/tray]
    type = internal/tray
    tray-size = 80%
    tray-spacing = 4px
  '';

  rofiConfig = ''
    configuration {
        modi: "drun,run,window";
        font: "MesloLGS Nerd Font 10";
        show-icons: true;
        terminal: "wezterm";
        drun-display-format: "{name}";
    }

    @theme "/dev/null"

    * {
        bg: #070f1c;
        bg-alt: #1e1e2e;
        fg: #e0d9c7;
        accent: #ea6847;

        background-color: @bg;
        text-color: @fg;
        border: 0;
        margin: 0;
        padding: 0;
        spacing: 0;
    }

    window {
        width: 30%;
        border: 2;
        border-color: @accent;
        background-color: @bg;
        padding: 10;
    }

    element {
        padding: 6 8;
        text-color: @fg;
    }

    element selected {
        background-color: @bg-alt;
        text-color: @accent;
    }

    entry {
        padding: 8;
        text-color: @fg;
    }

    inputbar {
        children: [entry];
    }
  '';
in

{
  # Boot settings & branding
  boot.zfs.forceImportRoot = false;
  isoImage.volumeID = "eir-recovery";
  isoImage.edition = "eir";
  isoImage.prependToMenuLabel = "Eir Recovery — ";
  isoImage.appendToMenuLabel = "";

  # Allow unfree packages (required for non-free firmware blobs e.g. Broadcom)
  nixpkgs.config.allowUnfree = true;

  # Hardware / Firmware support (all non-free blobs for max wifi/network compatibility)
  hardware.enableAllFirmware = true;

  # SSH — password auth, useful for headless recovery scenarios
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };

  # NetworkManager configuration
  networking.hostName = "eir-recovery";
  networking.networkmanager.enable = true;

  # zsh + oh-my-zsh (NixOS-managed, no ~/.oh-my-zsh needed)
  programs.zsh = {
    enable = true;
    ohMyZsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      custom = "${p10kCustom}";
      plugins = [
        "docker"
        "colored-man-pages"
        "colorize"
        "command-not-found"
        "git"
        "history-substring-search"
        "python"
        "sudo"
        "z"
      ];
    };
  };

  # tmux with pre-installed plugins (bypasses tpm)
  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      open
    ];
    extraConfig = ''
      set -g status-style "bg=#24273A,fg=#c6d0f5"
      set -g status-left "#[fg=#24273A,bg=#8caaee,bold] #S #[default] "
      set -g status-right "#[fg=#ca9ee6,bg=#303446] #{s|^$HOME|~|:pane_current_path} "
      set -g window-status-current-format "#[fg=#24273A,bg=#8caaee,bold] #I:#W "
      set -g window-status-format "#[fg=#c6d0f5,bg=#24273A] #I:#W "
    '';
  };

  # System packages
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    wezterm
    firefox
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
    (neovim.override {
      configure = {
        packages.eir.start = with vimPlugins; [
          rose-pine
          lightline-vim
          fzf-vim
          nvim-rg
          vim-fugitive
          vim-unimpaired
          vim-surround
          vim-commentary
          vim-eunuch
          vim-sexp-mappings-for-regular-people
          tabular
          rust-vim
          typescript-vim
          vim-clojure-static
          nvim-lspconfig
        ];
      };
    })
  ];

  programs.neovim.defaultEditor = true;

  # Fonts — MesloLGS NF required by wezterm config and powerlevel10k
  fonts.fontconfig.enable = true;
  fonts.enableDefaultPackages = true;
  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  # Default browser for xdg-open
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
  };

  # User account, autologin, default shell
  users.users.eir = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "eiR1!";
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "eir";
  };

  # Window Manager configuration
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.options = "caps:swapescape";
    windowManager.i3.enable = true;
  };

  # Populate /home/eir from nix store / inline strings at activation time
  system.activationScripts.eir-dotfiles = {
    deps = [ "users" ];
    text = ''
      dst="/home/eir"
      mkdir -p \
        "$dst/.vim" \
        "$dst/.claude" \
        "$dst/.config/wezterm" \
        "$dst/.config/lf" \
        "$dst/.config/i3" \
        "$dst/.config/polybar" \
        "$dst/.config/rofi"

      cp -rT --no-preserve=ownership ${resolvedDotfiles}/.vim    "$dst/.vim"    || true
      cp -rT --no-preserve=ownership ${resolvedDotfiles}/.claude "$dst/.claude" || true
      cp -rT --no-preserve=ownership ${resolvedDotfiles}/wezterm "$dst/.config/wezterm" || true
      cp -rT --no-preserve=ownership ${resolvedDotfiles}/lf      "$dst/.config/lf"      || true

      cp ${resolvedDotfiles}/.zshrc        "$dst/.zshrc"        || true
      cp ${resolvedDotfiles}/.bashrc       "$dst/.bashrc"       || true
      cp ${resolvedDotfiles}/.bash_aliases "$dst/.bash_aliases" || true
      cp ${resolvedDotfiles}/.p10k.zsh     "$dst/.p10k.zsh"     || true
      cp ${resolvedDotfiles}/.tmux.conf    "$dst/.tmux.conf"    || true
      cp ${resolvedDotfiles}/.vimrc        "$dst/.vimrc"        || true

      cat << 'EOF' > "$dst/.config/i3/config"
${i3Config}
EOF

      cat << 'EOF' > "$dst/.config/polybar/config.ini"
${polybarConfig}
EOF

      cat << 'EOF' > "$dst/.config/rofi/config.rasi"
${rofiConfig}
EOF

      chown -R eir:users "$dst" || true
    '';
  };
}

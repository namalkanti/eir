{ pkgs, dotfiles, lib, ... }:

let
  # powerlevel10k structured for oh-my-zsh's custom themes directory
  p10kCustom = pkgs.runCommand "p10k-ohmyzsh-custom" {} ''
    mkdir -p $out/themes
    ln -s ${pkgs.zsh-powerlevel10k}/share/zsh/themes/powerlevel10k $out/themes/powerlevel10k
  '';

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

    # tmux — strip tpm plugin declarations and run line; NixOS manages plugins
    cp -rL ${dotfiles}/.tmux.conf $out/.tmux.conf
    sed -i '/set -g @plugin/d'                         $out/.tmux.conf
    sed -i "/run '~\/.tmux\/plugins\/tpm\/tpm'/d"      $out/.tmux.conf

    # neovim — strip vim-plug block and patch fzf path; NixOS manages plugins
    cp -rL ${dotfiles}/.vimrc $out/.vimrc
    sed -i '/^call plug#begin/,/^call plug#end/d' $out/.vimrc
    sed -i "s|/bin/fzf|${pkgs.fzf}/bin/fzf|g"    $out/.vimrc
    cp -rL ${dotfiles}/.vim $out/.vim

    # Editor / terminal / file manager configs
    cp -rL ${dotfiles}/.config/wezterm         $out/wezterm
    cp -rL ${dotfiles}/.config/lf              $out/lf

    # tmux-powerline: config + bubble theme
    cp -rL ${dotfiles}/.config/tmux-powerline  $out/tmux-powerline-config
    mkdir -p $out/tmux-powerline-themes
    cp -rL ${dotfiles}/.tmux/plugins/tmux-powerline/themes/bubble.sh \
           $out/tmux-powerline-themes/bubble.sh

    # Claude — resolve symlinks, inject AGENTS.md, fix CLAUDE.md reference
    cp -rL ${dotfiles}/.claude       $out/.claude
    chmod u+w $out/.claude
    cp -rL ${dotfiles}/.pi/agent/AGENTS.md $out/.claude/AGENTS.md
    echo '@~/.claude/AGENTS.md' > $out/.claude/CLAUDE.md
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
      tmux-powerline
    ];
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

  # Keyboard configuration (swap Caps Lock and Escape)
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.options = "caps:swapescape";
    desktopManager.xfce.enable = true;
  };

  # Dotfiles — baked into ISO at build time (symlinks resolved, configs patched)
  isoImage.contents = [
    { source = "${resolvedDotfiles}/.zshrc";         target = "/home/eir/.zshrc"; }
    { source = "${resolvedDotfiles}/.bashrc";        target = "/home/eir/.bashrc"; }
    { source = "${resolvedDotfiles}/.bash_aliases";  target = "/home/eir/.bash_aliases"; }
    { source = "${resolvedDotfiles}/.p10k.zsh";      target = "/home/eir/.p10k.zsh"; }
    { source = "${resolvedDotfiles}/.tmux.conf";     target = "/home/eir/.tmux.conf"; }
    { source = "${resolvedDotfiles}/.vimrc";         target = "/home/eir/.vimrc"; }
    { source = "${resolvedDotfiles}/.vim";           target = "/home/eir/.vim"; }
    { source = "${resolvedDotfiles}/.claude";        target = "/home/eir/.claude"; }
    { source = "${resolvedDotfiles}/wezterm";        target = "/home/eir/.config/wezterm"; }
    { source = "${resolvedDotfiles}/lf";             target = "/home/eir/.config/lf"; }
    { source = "${resolvedDotfiles}/tmux-powerline-config";  target = "/home/eir/.config/tmux-powerline"; }
    { source = "${resolvedDotfiles}/tmux-powerline-themes";  target = "/home/eir/.config/tmux-powerline/themes"; }
  ];

  # Provision default XFCE window manager shortcuts (xfwm4)
  environment.etc."xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4" version="1.0">
      <properties name="defaults">
        <property name="general" type="empty">
          <property name="tile_up_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;w"/>
          <property name="tile_left_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;a"/>
          <property name="tile_down_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;d"/>
          <property name="tile_right_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;s"/>
          <property name="maximize_window_key" type="string" value="&lt;Alt&gt;r"/>
          <property name="workspace_1_key" type="string" value="&lt;Alt&gt;1"/>
          <property name="workspace_2_key" type="string" value="&lt;Alt&gt;2"/>
          <property name="workspace_3_key" type="string" value="&lt;Alt&gt;3"/>
          <property name="workspace_4_key" type="string" value="&lt;Alt&gt;4"/>
        </property>
      </properties>
    </channel>
  '';

  # Set wezterm as the default terminal emulator in XFCE
  environment.etc."xdg/xfce4/helpers.rc".text = ''
    TerminalEmulator=wezterm
    TerminalEmulatorDismissed=true
    WebBrowser=firefox
    WebBrowserDismissed=true
  '';

  # Provision general keyboard shortcuts (Terminal / File Manager)
  environment.etc."xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-keyboard-shortcuts" version="1.0">
      <properties name="commands" type="empty">
        <property name="custom" type="empty">
          <property name="&lt;Shift&gt;&lt;Alt&gt;t" type="string" value="wezterm"/>
          <property name="&lt;Shift&gt;&lt;Alt&gt;f" type="string" value="thunar"/>
        </property>
      </properties>
    </channel>
  '';
}

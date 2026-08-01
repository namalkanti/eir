{ pkgs, dotfiles, lib, ... }:

let
  # Resolve all symlinks from the dotfiles repo before copying into the ISO.
  # cp -rL dereferences symlinks so the squashfs contains only real files.
  resolvedDotfiles = pkgs.runCommand "dotfiles-resolved" {} ''
    mkdir -p $out
    cp -rL ${dotfiles}/.zshrc                     $out/.zshrc
    cp -rL ${dotfiles}/.bashrc                    $out/.bashrc
    cp -rL ${dotfiles}/.bash_aliases              $out/.bash_aliases
    cp -rL ${dotfiles}/.p10k.zsh                  $out/.p10k.zsh
    cp -rL ${dotfiles}/.tmux.conf                 $out/.tmux.conf
    cp -rL ${dotfiles}/.vimrc                     $out/.vimrc
    cp -rL ${dotfiles}/.vim                       $out/.vim
    cp -rL ${dotfiles}/.claude                    $out/.claude
    chmod u+w $out/.claude
    cp -rL ${dotfiles}/.pi/agent/AGENTS.md         $out/.claude/AGENTS.md
    echo '@~/.claude/AGENTS.md' > $out/.claude/CLAUDE.md
    cp -rL ${dotfiles}/.config/tmux-powerline     $out/tmux-powerline
    cp -rL ${dotfiles}/.config/wezterm            $out/wezterm
    cp -rL ${dotfiles}/.config/lf                 $out/lf
  '';
in

{
  # Boot settings & branding
  boot.zfs.forceImportRoot = false;
  isoImage.volumeID = "eir-recovery";
  isoImage.edition = "eir";

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

  # System packages
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
  ];

  # User account & autologin
  users.users.eir = {
    isNormalUser = true;
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

  # Dotfiles — copied directly into /home/eir at build time (symlinks resolved via cp -rL)
  isoImage.contents = [
    { source = "${resolvedDotfiles}/.zshrc";         target = "/home/eir/.zshrc"; }
    { source = "${resolvedDotfiles}/.bashrc";        target = "/home/eir/.bashrc"; }
    { source = "${resolvedDotfiles}/.bash_aliases";  target = "/home/eir/.bash_aliases"; }
    { source = "${resolvedDotfiles}/.p10k.zsh";      target = "/home/eir/.p10k.zsh"; }
    { source = "${resolvedDotfiles}/.tmux.conf";     target = "/home/eir/.tmux.conf"; }
    { source = "${resolvedDotfiles}/.vimrc";         target = "/home/eir/.vimrc"; }
    { source = "${resolvedDotfiles}/.vim";           target = "/home/eir/.vim"; }
    { source = "${resolvedDotfiles}/.claude";        target = "/home/eir/.claude"; }
    { source = "${resolvedDotfiles}/tmux-powerline"; target = "/home/eir/.config/tmux-powerline"; }
    { source = "${resolvedDotfiles}/wezterm";        target = "/home/eir/.config/wezterm"; }
    { source = "${resolvedDotfiles}/lf";             target = "/home/eir/.config/lf"; }
  ];

  # Provision default XFCE window manager shortcuts (xfwm4)
  environment.etc."xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4" version="1.0">
      <properties name="defaults">
        <property name="general" type="empty">
          <property name="tile_up_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;w"/>
          <property name="tile_left_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;a"/>
          <property name="tile_down_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;s"/>
          <property name="tile_right_key" type="string" value="&lt;Shift&gt;&lt;Alt&gt;d"/>
          <property name="maximize_window_key" type="string" value="&lt;Alt&gt;r"/>
          <property name="workspace_1_key" type="string" value="&lt;Alt&gt;1"/>
          <property name="workspace_2_key" type="string" value="&lt;Alt&gt;2"/>
          <property name="workspace_3_key" type="string" value="&lt;Alt&gt;3"/>
          <property name="workspace_4_key" type="string" value="&lt;Alt&gt;4"/>
        </property>
      </properties>
    </channel>
  '';

  # Provision general keyboard shortcuts (Terminal / File Manager)
  environment.etc."xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-keyboard-shortcuts" version="1.0">
      <properties name="commands" type="empty">
        <property name="custom" type="empty">
          <property name="&lt;Shift&gt;&lt;Alt&gt;t" type="string" value="xfce4-terminal"/>
          <property name="&lt;Shift&gt;&lt;Alt&gt;f" type="string" value="thunar"/>
        </property>
      </properties>
    </channel>
  '';
}

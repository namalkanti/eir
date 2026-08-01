{ pkgs, ... }:

{
  # Boot settings & branding
  boot.zfs.forceImportRoot = false;
  isoImage.volumeID = "eir-recovery";
  isoImage.edition = "Eir Recovery";

  # User account & autologin
  users.users.eir = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "eir";
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

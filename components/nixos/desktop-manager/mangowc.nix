{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.mangowc = {
    enable = lib.mkEnableOption "MangoWC tiling Wayland compositor";
  };

  config = lib.mkIf config.components.desktop.mangowc.enable {
    programs.mango.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    # Dolphin without Plasma: kio-extras for thumbnails/sftp/smb/trash,
    # kio-fuse so non-KDE apps can open remote files, thumbnailers for media.
    environment.systemPackages = with pkgs.kdePackages; [
      dolphin
      kio
      kio-extras
      kio-fuse
      kdegraphics-thumbnailers
      ffmpegthumbs
      qtsvg
    ];

    # Outside Plasma there is no applications.menu, so KService finds no apps
    # and Dolphin's "Open With" stays empty. A minimal menu listing every
    # installed app is enough (Plasma's file would pull in plasma-workspace).
    environment.etc."xdg/menus/applications.menu".text = ''
      <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
        "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
      <Menu>
        <Name>Applications</Name>
        <DefaultAppDirs/>
        <DefaultDirectoryDirs/>
        <Include><All/></Include>
      </Menu>
    '';
  };
}

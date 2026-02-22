{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.niri = {
    enable = lib.mkEnableOption "Niri scrollable tiling Wayland compositor";
  };

  config = lib.mkIf config.components.desktop.niri.enable {
    programs.niri.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
  };
}

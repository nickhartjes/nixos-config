{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.display.gdm;
in {
  options.components.display.gdm.enable = mkEnableOption "enable GDM (GNOME Display Manager)";

  config = mkIf cfg.enable {
    services.xserver.displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };
  };
}

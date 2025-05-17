{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.extraServices.displayManager.gdm;
in {
  options.extraServices.displayManager.gdm.enable = mkEnableOption "enable GDM (GNOME Display Manager)";

  config = mkIf cfg.enable {
      services.xserver.displayManager = {
      
      gdm = {
        enable = true;
        wayland = true;
      };

    
    };
  };
}

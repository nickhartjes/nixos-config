{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.extraServices.displayManager.sddm;
in {
  options.extraServices.displayManager.sddm.enable = mkEnableOption "enable Simple Desktop Display Manager (SDDM)";

  config = mkIf cfg.enable {
      services.xserver.displayManager = {
      
      sddm = {
        enable = true;
        wayland.enable = true;
      };

    
    };
  };
}

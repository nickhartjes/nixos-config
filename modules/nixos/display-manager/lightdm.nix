{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.extraServices.displayManager.lightdm;
in {
  options.extraServices.displayManager.lightdm.enable = mkEnableOption "enable Lightdm";

  config = mkIf cfg.enable {
      services.xserver.displayManager = {
      
      lightdm = {
        enable = true;
      };

    
    };
  };
}

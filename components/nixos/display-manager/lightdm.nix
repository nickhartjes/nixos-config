{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.display.lightdm;
in {
  options.components.display.lightdm.enable = mkEnableOption "enable Lightdm";

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      displayManager = {
        lightdm = {
          enable = true;
        };
      };
    };
  };
}

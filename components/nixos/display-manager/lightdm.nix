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
    services.xserver.displayManager = {
      lightdm = {
        enable = true;
      };
    };
  };
}

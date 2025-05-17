{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.extraServices.desktopManager.cinnamon;
in {
  options.extraServices.desktopManager.cinnamon.enable = mkEnableOption "enable cinnamon";

  config = mkIf cfg.enable {
    services = {
      xserver = {
        desktopManager= {
          cinnamon = {
            enable = true;
          };
        };
      };
      cinnamon.apps.enable = true;
    };
  };
}

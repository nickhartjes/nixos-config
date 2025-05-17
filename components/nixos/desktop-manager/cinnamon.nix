{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.desktop.cinnamon;
in {
  options.components.desktop.cinnamon.enable = mkEnableOption "enable cinnamon";

  config = mkIf cfg.enable {
    services = {
      xserver = {
        desktopManager = {
          cinnamon = {
            enable = true;
          };
        };
      };
      cinnamon.apps.enable = true;
    };
  };
}

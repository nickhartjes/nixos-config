{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.desktop.pantheon;
in {
  options.components.desktop.pantheon.enable = mkEnableOption "enable pantheon";

  config = mkIf cfg.enable {
    services = {
      xserver = {
        desktopManager = {
          pantheon = {
            enable = true;
          };
        };
      };
      pantheon.apps.enable = true;
    };
  };
}

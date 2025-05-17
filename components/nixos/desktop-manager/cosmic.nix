{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.desktop.cosmic;
in {
  options.components.desktop.cosmic.enable = mkEnableOption "enable cinnamon";

  config = mkIf cfg.enable {
    services = {
      desktopManager = {
        cosmic = {
          enable = true;
        };
      };
    };
  };
}

{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.components.desktop.plasma;
in {
  options.components.desktop.plasma.enable = mkEnableOption "KDE plasma config";

  config = mkIf cfg.enable {
    services = {
      desktopManager = {
        plasma6 = {
          enable = true;
        };
      };
    };
  };
}

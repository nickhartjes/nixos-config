{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.features.desktop.plasma;
in {
  options.features.desktop.plasma.enable = mkEnableOption "KDE plasma config";

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

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.display.cosmicGreeter;
in {
  options.components.display.cosmicGreeter.enable = mkEnableOption "enable Cosmic Greeter";

  config = mkIf cfg.enable {
    services.displayManager = {
      cosmic-greeter = {
        enable = true;
      };
    };
  };
}

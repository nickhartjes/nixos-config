{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.hardware.displaylink;
in {
  options.components.hardware.displaylink.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = ["displaylink" "modesetting"];

    environment = {
      systemPackages = with pkgs; [
        displaylink
      ];
    };
  };
}

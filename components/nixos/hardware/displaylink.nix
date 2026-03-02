{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.hardware.displaylink;
  evdi = config.boot.kernelPackages.evdi;
  displaylink = pkgs.displaylink.override { inherit evdi; };
in {
  options.components.hardware.displaylink.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = ["modesetting"];

    boot.extraModulePackages = [evdi];
    boot.kernelModules = ["evdi"];

    environment.systemPackages = [displaylink];
    services.udev.packages = [displaylink];

    systemd.services.dlm = {
      description = "DisplayLink Manager Service";
      after = ["display-manager.service"];
      conflicts = ["getty@tty7.service"];
      serviceConfig = {
        ExecStart = "${displaylink}/bin/DisplayLinkManager";
        Restart = "always";
        RestartSec = 5;
        LogsDirectory = "displaylink";
      };
    };
  };
}

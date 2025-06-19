{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.system.mission-center = {
    enable = lib.mkEnableOption "Mission Center - Monitor your CPU, Memory, Disk, Network and GPU usage";
  };

  config = lib.mkIf config.components.application.system.mission-center.enable {
    home.packages = with pkgs; [
      mission-center
    ];
  };
}

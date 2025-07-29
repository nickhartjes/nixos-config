{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.monitoring.nvtop = {
    enable = lib.mkEnableOption "NVTop AMD monitoring tool";
  };

  config = lib.mkIf config.components.application.monitoring.nvtop.enable {
    home.packages = with pkgs; [
      nvtopPackages.amd
    ];
  };
}

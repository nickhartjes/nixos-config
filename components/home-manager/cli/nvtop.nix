{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.nvtop;
in {
  options.components.cli.nvtop.enable = mkEnableOption "enable nvtop";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [nvtopPackages.amd];
  };
}

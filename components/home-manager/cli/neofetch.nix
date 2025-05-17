{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.neofetch;
in {
  options.components.cli.neofetch.enable = mkEnableOption "enable neofetch";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [neofetch];
  };
}

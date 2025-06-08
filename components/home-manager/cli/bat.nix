{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.bat;
in {
  options.components.cli.bat.enable = mkEnableOption "enable bat, a cat clone with wings.";

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [batdiff batman batgrep batwatch];
    };
  };
}

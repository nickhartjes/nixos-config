{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.terminal.wezterm;
in {
  options.components.terminal.wezterm.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    programs = {
      wezterm = {
        enable = true;
      };
    };
  };
}

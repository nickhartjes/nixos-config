{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.terminal.alacritty;
in {
  options.components.terminal.alacritty.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    programs = {
      alacritty = {
        enable = true;
      };
    };
  };
}

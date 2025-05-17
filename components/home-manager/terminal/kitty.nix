{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.terminal.kitty;
in {
  options.components.terminal.kitty.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    programs = {
      kitty = {
        enable = true;
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.terminal.foot;
in {
  options.components.terminal.foot.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    programs = {
      foot = {
        enable = true;
        server.enable = true;
      };
    };
  };
}

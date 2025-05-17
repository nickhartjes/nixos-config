{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.alacritty.foot;
in {
  options.components.alacritty.foot.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    programs = {
      alacritty = {
        enable = true;
      };
    };
  };
}

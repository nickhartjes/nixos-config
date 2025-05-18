{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.system.fonts;
in {
  options.components.system.fonts.enable = mkEnableOption "enable fonts";

  config = mkIf cfg.enable {
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      (import ../../../pkgs/fonts-custom {inherit stdenv lib;})
    ];
  };
}

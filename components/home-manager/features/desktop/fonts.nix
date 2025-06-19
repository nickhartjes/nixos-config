{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.desktop.fonts;
in {
  options.components.desktop.fonts.enable =
    mkEnableOption "install additional fonts for desktop apps";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.inconsolata
      font-manager
      font-awesome_5
      noto-fonts
    ];
  };
}

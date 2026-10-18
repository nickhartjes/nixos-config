{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.terminal.ghostty;
  stylixOn = config.components.features.desktop.stylix.enable;
in {
  options.components.terminal.ghostty.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    programs = {
      ghostty = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
        settings =
          {
            font-family = "ComicCodeLigatures Nerd Font";
            font-size = 10;
          }
          // optionalAttrs (!stylixOn) {theme = "Catppuccin Mocha";};
      };
    };
  };
}

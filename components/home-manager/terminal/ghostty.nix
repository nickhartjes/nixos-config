{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.terminal.ghostty;
in {
  options.components.terminal.ghostty.enable = mkEnableOption "enable displaylink";

  config = mkIf cfg.enable {
    programs = {
      ghostty = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
        settings = {
          font-family = "ComicCodeLigatures Nerd Font";
          theme = "catppuccin-mocha";
          font-size = 10;
        };
      };
    };
  };
}

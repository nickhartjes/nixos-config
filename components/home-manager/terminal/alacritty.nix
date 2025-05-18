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
        settings = {
          window = {
            opacity = 0.9;
            padding = {
              x = 0;
              y = 0;
            };
          };
          font = {
            size = 7.0;
            normal = {
              family = "ComicCodeLigatures Nerd Font";
              style = "Regular";
            };
          };
        };
      };
    };
  };
}

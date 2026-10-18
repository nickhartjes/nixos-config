{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  cfg = config.components.system.stylix;
in {
  options.components.system.stylix.enable = lib.mkEnableOption "Stylix Tokyo Night color scheme";

  # The stylix module is only imported on framework-13; other hosts must not
  # define stylix.* (that would fail with "option does not exist").
  config = lib.optionalAttrs (options ? stylix) (lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      # Targets are opted into per application, nothing is themed implicitly.
      autoEnable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
      polarity = "dark";
      fonts = {
        monospace = {
          package = import ../../../pkgs/fonts-custom {inherit (pkgs) stdenv lib;};
          name = "ComicCodeLigatures Nerd Font";
        };
        sizes.terminal = 10;
      };
    };
  });
}

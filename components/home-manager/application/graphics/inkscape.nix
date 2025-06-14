{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.graphics.inkscape = {
    enable = lib.mkEnableOption "Inkscape vector graphics editor";
  };

  config = lib.mkIf config.components.application.graphics.inkscape.enable {
    home.packages = with pkgs; [
      inkscape
    ];

    # Inkscape is free software, no need for allowUnfreePredicate
  };
}

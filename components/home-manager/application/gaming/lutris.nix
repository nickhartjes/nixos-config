{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.gaming.lutris = {
    enable = lib.mkEnableOption "Lutris gaming platform";
  };

  config = lib.mkIf config.components.application.gaming.lutris.enable {
    home.packages = with pkgs; [
      lutris
      protonup-qt
      wine
      winetricks
    ];

  };
}

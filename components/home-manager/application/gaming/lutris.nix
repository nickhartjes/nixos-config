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

    # Add lutris to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "lutris"
      ];
  };
}

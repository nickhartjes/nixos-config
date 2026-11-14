{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application."3d".bambu-studio = {
    enable = lib.mkEnableOption "Bambu Studio 3D printing software";
  };

  config = lib.mkIf config.components.application."3d".bambu-studio.enable {
    home.packages = [
      (pkgs.callPackage ../../../../pkgs/bambu-studio {})
    ];
  };
}

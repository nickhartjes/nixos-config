{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application."3d".solidcraft = {
    enable = lib.mkEnableOption "SolidCraft parametric 3D CAD";
  };

  config = lib.mkIf config.components.application."3d".solidcraft.enable {
    home.packages = [
      (pkgs.callPackage ../../../../pkgs/solidcraft {})
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application."3d".freecad = {
    enable = lib.mkEnableOption "FreeCAD 3D CAD/MCAD/CAx/CAE/PLM modeler";
  };

  config = lib.mkIf config.components.application."3d".freecad.enable {
    home.packages = with pkgs; [
      freecad
    ];
  };
}
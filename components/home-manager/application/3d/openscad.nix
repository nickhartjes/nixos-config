{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application."3d".openscad = {
    enable = lib.mkEnableOption "OpenSCAD 3D parametric model compiler";
  };

  config = lib.mkIf config.components.application."3d".openscad.enable {
    home.packages = with pkgs; [
      openscad
    ];
  };
}
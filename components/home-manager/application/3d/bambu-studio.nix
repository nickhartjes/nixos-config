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
    home.packages = with pkgs; [
      bambu-studio
    ];

    # Bambu Studio is proprietary software
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "bambu-studio"
      ];
  };
}
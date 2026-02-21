{
  config,
  lib,
  ...
}: let
  cfg = config.components.features.desktop.wallpapers;
  wallpaperDir = ../../../../assets/wallpapers;
  wallpaperFiles = builtins.attrNames (builtins.readDir wallpaperDir);
in {
  options.components.features.desktop.wallpapers = {
    enable = lib.mkEnableOption "Declarative wallpaper management";
    default = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Filename of the default wallpaper from assets/wallpapers/ (e.g. 'aishot-2697.jpg')";
    };
  };

  config = lib.mkIf cfg.enable {
    # Symlink all wallpapers from the nix store to ~/Pictures/wallpapers/
    home.file = builtins.listToAttrs (map (name: {
      name = "Pictures/wallpapers/${name}";
      value = {
        source = wallpaperDir + "/${name}";
      };
    }) wallpaperFiles)
    // lib.optionalAttrs (cfg.default != "") {
      ".config/wallpaper" = {
        source = wallpaperDir + "/${cfg.default}";
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.graphics.gimp = {
    enable = lib.mkEnableOption "GIMP image editor";
  };

  config = lib.mkIf config.components.application.graphics.gimp.enable {
    home.packages = with pkgs; [
      gimp
    ];

    # GIMP is free software, no need for allowUnfreePredicate
  };
}

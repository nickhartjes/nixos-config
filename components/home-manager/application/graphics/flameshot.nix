{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.graphics.flameshot = {
    enable = lib.mkEnableOption "Flameshot screenshot tool";
  };

  config = lib.mkIf config.components.application.graphics.flameshot.enable {
    home.packages = with pkgs; [
      flameshot
    ];

    # Flameshot is free software, no need for allowUnfreePredicate
  };
}

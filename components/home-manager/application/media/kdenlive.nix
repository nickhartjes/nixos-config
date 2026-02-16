{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.media.kdenlive = {
    enable = lib.mkEnableOption "Kdenlive video editor";
  };

  config = lib.mkIf config.components.application.media.kdenlive.enable {
    home.packages = with pkgs; [
      kdePackages.kdenlive
    ];
  };
}

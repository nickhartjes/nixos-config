{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.media.vlc = {
    enable = lib.mkEnableOption "VLC media player";
  };

  config = lib.mkIf config.components.application.media.vlc.enable {
    home.packages = with pkgs; [
      vlc
    ];
  };
}

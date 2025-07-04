{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.media.mpv = {
    enable = lib.mkEnableOption "MPV media player";
  };

  config = lib.mkIf config.components.application.media.mpv.enable {
    programs.mpv.enable = true;
  };
}

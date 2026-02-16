{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.media.obs = {
    enable = lib.mkEnableOption "OBS Studio";
  };

  config = lib.mkIf config.components.application.media.obs.enable {
    programs.obs-studio = {
      enable = true;
    };
  };
}

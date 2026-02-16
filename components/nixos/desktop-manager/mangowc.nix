{
  config,
  lib,
  ...
}: {
  options.components.desktop.mangowc = {
    enable = lib.mkEnableOption "MangoWC tiling Wayland compositor";
  };

  config = lib.mkIf config.components.desktop.mangowc.enable {
    programs.mango.enable = true;

    # Environment variables for Wayland
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };
  };
}

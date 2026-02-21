{
  config,
  lib,
  ...
}: let
  # Any Wayland compositor that's enabled should get these env vars
  waylandEnabled =
    config.components.desktop.niri.enable
    || config.components.desktop.mangowc.enable
    || config.components.desktop.hyprland.enable
    || config.components.desktop.sway.enable;
in {
  config = lib.mkIf waylandEnabled {
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

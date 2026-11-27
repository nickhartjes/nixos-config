{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.system.androidEmulatorRuntime;
in {
  options.components.system.androidEmulatorRuntime = {
    enable = mkEnableOption ''
      shared libraries in nix-ld for the Android emulator from the SDK (e.g. via
      mise's android-sdk). It bundles Qt and most xcb libraries itself, but loads
      these from the system. Its Qt has no Wayland plugin: run it with
      QT_QPA_PLATFORM=xcb'';
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libbsd
        libice
        libsm
        libxi
        libpng
        libpulseaudio
        util-linux.lib # libuuid
        libxkbfile
        zlib
      ];
    };
  };
}

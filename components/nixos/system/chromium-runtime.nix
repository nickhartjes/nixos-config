{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.system.chromiumRuntime;
in {
  options.components.system.chromiumRuntime = {
    enable = mkEnableOption ''
      shared libraries in nix-ld for downloaded (generic Linux) Chromium builds,
      such as the browsers `playwright install` fetches for a project's own
      Playwright version'';
  };

  config = mkIf cfg.enable {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        glib
        nspr
        nss
        at-spi2-core # atk, atk-bridge, atspi
        dbus
        expat
        libxcb
        libxkbcommon
        systemd # libudev
        alsa-lib
        libgbm
        libdrm
        pango
        cairo
        cups
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
      ];
    };
  };
}

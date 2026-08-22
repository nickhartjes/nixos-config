{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.niri = {
    enable = lib.mkEnableOption "Niri scrollable tiling Wayland compositor";
  };

  config = lib.mkIf config.components.desktop.niri.enable {
    programs.niri.enable = true;

    # TEMP (2026-08-14): niri-flake's own niri derivation does
    # `assert libdisplay-info_0_2.version == "0.2.0"`, but nixpkgs removed the
    # `libdisplay-info_0_2` alias (only 0.3.0/0.4.0 remain). The flake has a
    # `libdisplay-info_0_2 ? libdisplay-info` fallback, but it never fires
    # because the alias still *exists* as a throw, so eval fails outright
    # (sodiboo/niri-flake#1851; fix PR #1850 still unmerged, and the latest
    # niri-flake rev is the one we already pin). nixpkgs ships niri itself now,
    # so use that instead. Drop this once niri-flake is fixed.
    programs.niri.package = pkgs.niri;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };
  };
}

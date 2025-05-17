{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.desktop.plasma;
in {
  options.components.desktop.plasma.enable = mkEnableOption "enable plasma";

  config = mkIf cfg.enable {
    services = {
      desktopManager = {
        plasma6 = {
          enable = true;
        };
      };
    };
    environment.systemPackages = with pkgs; [
      catppuccin-kde # Catppuccin theme for KDE
      catppuccin-cursors # Catppuccin cursors for KDE

      kdePackages.plasma-thunderbolt # Thunderbolt support
    ];
    environment.plasma6.excludePackages = with pkgs; [
      kdePackages.plasma-browser-integration # Browser integration
      kdePackages.konsole # Terminal emulator
      kdePackages.elisa # Music player
      kdePackages.khelpcenter # Help center
    ];
  };
}

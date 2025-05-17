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
      catppuccin-kde
      catppuccin-cursors
      kdePackages.yakuake
      kdePackages.kpmcore
      kdePackages.partitionmanager
      kdePackages.kio-admin
      kdePackages.plasma-thunderbolt
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.extraServices.desktopManager.plasma;
in {
  options.extraServices.desktopManager.plasma.enable = mkEnableOption "enable plasma";

  config = mkIf cfg.enable {
      services = {
    desktopManager= {
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

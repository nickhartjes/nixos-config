{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.plasma = {
    enable = lib.mkEnableOption "KDE Plasma desktop environment";
  };

  config = lib.mkIf config.components.desktop.plasma.enable {
    services.xserver = {
      enable = true;
    };
    services.desktopManager.plasma6.enable = true;

    # Enable sound
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Enable NetworkManager
    networking.networkmanager.enable = true;

    # Basic system packages
    environment.systemPackages = with pkgs.kdePackages; [
      kate
      dolphin
      konsole
      spectacle
      okular
    ];

    # Exclude some default KDE applications if desired
    environment.plasma5.excludePackages = with pkgs.libsForQt5; [
      # Add packages to exclude here if needed
      # elisa
      # gwenview
      # khelpcenter
    ];
  };
}

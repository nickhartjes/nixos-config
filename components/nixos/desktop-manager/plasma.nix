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
      desktopManager.plasma5.enable = true;
    };

    # Enable sound
    hardware.pulseaudio.enable = false;
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
    environment.systemPackages = with pkgs; [
      firefox
      thunderbird
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

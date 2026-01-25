{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.cosmic = {
    enable = lib.mkEnableOption "COSMIC desktop environment";
  };

  config = lib.mkIf config.components.desktop.cosmic.enable {
    services.desktopManager.cosmic.enable = true;

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
    environment.systemPackages = with pkgs; [
      examine # System information viewer for the COSMIC Desktop
      tasks #Cosmic task manager
      quick-webapps # Webapp integration for COSMIC

      cosmic-greeter
      cosmic-wallpapers
      cosmic-ext-tweaks
      cosmic-ext-calculator
      cosmic-ext-applet-caffeine
      cosmic-ext-applet-minimon
      cosmic-ext-applet-privacy-indicator
      cosmic-workspaces-epoch
    ];
  };
}

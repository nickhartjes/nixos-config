{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };

  config = lib.mkIf config.components.desktop.gnome.enable {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
    };

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

    # Exclude some default GNOME applications
    environment.gnome.excludePackages = with pkgs; [
      gnome-photos
      gnome-tour
      gedit
      cheese
      gnome-music
      epiphany
      geary
      gnome-characters
      tali
      iagno
      hitori
      atomix
    ];

    # Basic system packages
    environment.systemPackages = with pkgs; [
      firefox
      thunderbird
      gnome.gnome-tweaks
      gnomeExtensions.appindicator
    ];
  };
}

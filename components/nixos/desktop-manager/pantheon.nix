{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.pantheon = {
    enable = lib.mkEnableOption "Pantheon desktop environment";
  };

  config = lib.mkIf config.components.desktop.pantheon.enable {
    services.xserver = {
      enable = true;
      desktopManager.pantheon.enable = true;
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

    # Basic system packages
    environment.systemPackages = with pkgs; [
      firefox
      thunderbird
    ];

    # Exclude some default Pantheon applications if desired
    environment.pantheon.excludePackages = with pkgs.pantheon; [
      # Add packages to exclude here if needed
    ];
  };
}

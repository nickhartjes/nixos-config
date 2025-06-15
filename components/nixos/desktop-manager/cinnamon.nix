{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.cinnamon = {
    enable = lib.mkEnableOption "Cinnamon desktop environment";
  };

  config = lib.mkIf config.components.desktop.cinnamon.enable {
    services.xserver = {
      enable = true;
      desktopManager.cinnamon.enable = true;
    };

    # Enable sound with PipeWire (modern audio system)
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
      libreoffice
      vlc
    ];
  };
}

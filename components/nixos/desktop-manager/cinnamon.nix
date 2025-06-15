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

    # Enable sound
    sound.enable = lib.mkDefault true;
    services.pulseaudio.enable = true;

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

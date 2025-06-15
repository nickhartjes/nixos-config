{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.sway = {
    enable = lib.mkEnableOption "Sway window manager";
  };

  config = lib.mkIf config.components.desktop.sway.enable {
    # Enable Wayland
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        # Core Sway components
        swaylock
        swayidle
        swaybg
        swaynotificationcenter

        # Wayland utilities
        wl-clipboard
        wf-recorder
        grim
        slurp

        # Application launcher
        wofi
        rofi-wayland

        # Terminal
        foot

        # Status bar
        waybar

        # Audio control
        pavucontrol

        # Network management
        networkmanagerapplet

        # File manager
        thunar

        # Image viewer
        imv

        # Video player
        mpv

        # PDF viewer
        zathura
      ];
    };

    # Enable XDG portal for Wayland
    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };

    # Security services
    security.polkit.enable = true;
    security.pam.services.swaylock = {};

    # Audio support
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = lib.mkDefault true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    # Fonts
    fonts.packages = with pkgs; [
      font-awesome
      noto-fonts
      noto-fonts-emoji
    ];

    # Environment variables
    environment.sessionVariables = {
      # Wayland-specific variables
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    # System packages
    environment.systemPackages = with pkgs; [
      # Additional Wayland tools
      wlr-randr
      wayland-utils
      wayland-protocols
    ];
  };
}

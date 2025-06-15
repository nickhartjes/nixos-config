{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
  };

  config = lib.mkIf config.components.desktop.hyprland.enable {
    # Enable Hyprland
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    # XDG portal configuration for Hyprland
    xdg.portal = {
      enable = true;
      wlr.enable = lib.mkDefault false; # Disable wlr portal as Hyprland has its own
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
    };

    # Security services
    security.polkit.enable = true;
    security.pam.services.hyprlock = {};

    # Audio support
    services.pulseaudio.enable = false;
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
      nerd-fonts.noto
    ];

    # Environment variables for Hyprland
    environment.sessionVariables = {
      # Wayland-specific variables
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    # System packages for Hyprland
    environment.systemPackages = with pkgs; [
      # Core Hyprland ecosystem
      hyprpaper # Wallpaper utility
      hyprlock # Screen locker
      hypridle # Idle management
      hyprpicker # Color picker
      hyprshot # Screenshot utility

      # Wayland utilities
      wl-clipboard # Clipboard manager
      wf-recorder # Screen recorder
      grim # Screenshot tool
      slurp # Region selection

      # Application launcher
      wofi
      rofi-wayland

      # Terminal
      foot
      kitty

      # Status bar
      waybar
      eww

      # Audio control
      pavucontrol

      # Network management
      networkmanagerapplet

      # File manager
      xfce.thunar
      kdePackages.dolphin

      # Image viewer
      imv

      # Video player
      mpv

      # PDF viewer
      zathura

      # Notification daemon
      mako
      dunst

      # Additional Wayland tools
      wlr-randr
      wayland-utils
      wayland-protocols

      # Theme tools
      qt5.qtwayland
      qt6.qtwayland
      libsForQt5.qt5ct
      qt6Packages.qt6ct
    ];

    # Enable hardware acceleration
    hardware.graphics = {
      enable = true;
    };

    # Bluetooth support (common for modern desktop setups)
    hardware.bluetooth.enable = lib.mkDefault true;
    services.blueman.enable = lib.mkDefault true;

    # Enable printing support
    services.printing.enable = lib.mkDefault true;
    services.printing.drivers = with pkgs; [cups-filters];

    # Enable location services (for night light, etc.)
    services.geoclue2.enable = lib.mkDefault true;
  };
}

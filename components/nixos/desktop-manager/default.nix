{
  config,
  lib,
  ...
}: let
  cfg = config.components.desktop;
  # Full desktop environments that conflict with each other
  enabledDEs =
    lib.count (x: x) [
      cfg.cinnamon.enable
      cfg.cosmic.enable
      cfg.gnome.enable
      cfg.pantheon.enable
      cfg.plasma.enable
    ];
in {
  imports = [
    ./cinnamon.nix
    ./cosmic.nix
    ./gnome.nix
    ./pantheon.nix
    ./plasma.nix
    ./sway.nix
    ./hyprland.nix
    ./mangowc.nix
    ./niri.nix
    ./wayland-env.nix
  ];

  config.assertions = [
    {
      assertion = enabledDEs <= 1;
      message = "Only one full desktop environment (Plasma, GNOME, Cinnamon, Pantheon, COSMIC) can be enabled at a time. Found ${toString enabledDEs} enabled.";
    }
  ];
}

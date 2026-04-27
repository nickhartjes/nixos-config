{
  config,
  lib,
  ...
}: let
  cfg = config.components.display;
  enabledDMs =
    lib.count (x: x) [
      cfg.gdm.enable
      cfg.lightdm.enable
      cfg.sddm.enable
      cfg.cosmic-greeter.enable
      cfg.greetd.enable
    ];
in {
  imports = [
    ./gdm.nix
    ./lightdm.nix
    ./sddm.nix
    ./cosmic-greeter.nix
    ./greetd.nix
  ];

  config = {
    assertions = [
      {
        assertion = enabledDMs <= 1;
        message = "Only one display manager can be enabled at a time. Found ${toString enabledDMs} enabled.";
      }
    ];

    # Centrally disable all display managers. Individual modules override
    # their own with mkForce true. This prevents desktop environments
    # (e.g. Plasma, GNOME) from implicitly enabling their preferred DM.
    services.displayManager.gdm.enable = lib.mkForce cfg.gdm.enable;
    services.xserver.displayManager.lightdm.enable = lib.mkForce cfg.lightdm.enable;
    services.displayManager.sddm.enable = lib.mkForce cfg.sddm.enable;
    services.displayManager.cosmic-greeter.enable = lib.mkForce cfg.cosmic-greeter.enable;
    services.greetd.enable = lib.mkForce (cfg.greetd.enable || cfg.cosmic-greeter.enable);
  };
}

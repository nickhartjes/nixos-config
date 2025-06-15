{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.display.greetd = {
    enable = lib.mkEnableOption "greetd display manager";
    defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "sway";
      description = "Default session to launch";
    };
  };

  config = lib.mkIf config.components.display.greetd.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${config.components.display.greetd.defaultSession}";
          user = "greeter";
        };
      };
    };

    # Ensure other display managers are disabled
    services.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    services.displayManager.sddm.enable = lib.mkForce false;
    services.displayManager.cosmic-greeter.enable = lib.mkForce false;
  };
}

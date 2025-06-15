{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.display.cosmic-greeter = {
    enable = lib.mkEnableOption "COSMIC greeter display manager";
  };

  config = lib.mkIf config.components.display.cosmic-greeter.enable {
    services.displayManager.cosmic-greeter.enable = true;

    # Ensure other display managers are disabled
    services.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    services.displayManager.sddm.enable = lib.mkForce false;
    services.greetd.enable = lib.mkForce false;
  };
}

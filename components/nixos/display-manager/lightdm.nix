{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.display.lightdm = {
    enable = lib.mkEnableOption "LightDM display manager";
  };

  config = lib.mkIf config.components.display.lightdm.enable {
    services.xserver.displayManager.lightdm.enable = true;

    # Ensure other display managers are disabled
    services.displayManager.gdm.enable = lib.mkForce false;
    services.displayManager.sddm.enable = lib.mkForce false;
    services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    services.greetd.enable = lib.mkForce false;
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.display.sddm = {
    enable = lib.mkEnableOption "SDDM display manager";
  };

  config = lib.mkIf config.components.display.sddm.enable {
    services.xserver.displayManager.sddm.enable = true;

    # Ensure other display managers are disabled
    services.xserver.displayManager.gdm.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    services.greetd.enable = lib.mkForce false;
  };
}

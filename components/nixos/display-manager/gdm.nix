{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.display.gdm = {
    enable = lib.mkEnableOption "GDM display manager";
  };

  config = lib.mkIf config.components.display.gdm.enable {
    services.xserver.displayManager.gdm.enable = true;

    # Ensure other display managers are disabled
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    services.xserver.displayManager.sddm.enable = lib.mkForce false;
    services.displayManager.cosmic-greeter.enable = lib.mkForce false;
    services.greetd.enable = lib.mkForce false;
  };
}

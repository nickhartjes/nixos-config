{lib, ...}: {
  options.components.display.lightdm = {
    enable = lib.mkEnableOption "LightDM display manager";
  };
}

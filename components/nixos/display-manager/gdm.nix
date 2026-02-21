{lib, ...}: {
  options.components.display.gdm = {
    enable = lib.mkEnableOption "GDM display manager";
  };
}

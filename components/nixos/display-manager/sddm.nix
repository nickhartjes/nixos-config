{lib, ...}: {
  options.components.display.sddm = {
    enable = lib.mkEnableOption "SDDM display manager";
  };
}

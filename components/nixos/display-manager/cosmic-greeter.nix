{lib, ...}: {
  options.components.display.cosmic-greeter = {
    enable = lib.mkEnableOption "COSMIC greeter display manager";
  };
}

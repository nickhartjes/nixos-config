{
  config,
  lib,
  ...
}: {
  options.components.display.sddm = {
    enable = lib.mkEnableOption "SDDM display manager";
  };

  config = lib.mkIf config.components.display.sddm.enable {
    # Run SDDM greeter on Wayland instead spawning an X server.
    # mkDefault so host can override back X11 if needed.
    services.displayManager.sddm.wayland.enable = lib.mkDefault true;
  };
}

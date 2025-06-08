{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.display.sddm;
in {
  options.components.display.sddm.enable = mkEnableOption "enable Simple Desktop Display Manager (SDDM)";

  config = mkIf cfg.enable {
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}

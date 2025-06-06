{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.system.yubikey;
in {
  options.components.system.yubikey.enable = mkEnableOption "enable yubikey";

  config = mkIf cfg.enable {
    security.pam.u2f = {
      enable = true;
      settings = {
        interactive = true;
        cue = true;
      };
    };

    # Smartcard mode
    services.pcscd.enable = true;
  };
}

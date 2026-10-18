{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.system.yubikey;
in {
  options.components.system.yubikey = {
    enable = mkEnableOption "enable yubikey";
    # Output of `pamu2fcfg -u nh -N` (one line per user). Key handles and
    # public keys only, so it is safe in the public repo. Empty means u2f never
    # matches and PAM falls through to the password.
    u2fMappings = mkOption {
      type = types.lines;
      default = "";
      description = "pam_u2f authfile contents (pamu2fcfg output).";
    };
  };

  config = mkIf cfg.enable {
    security.pam.u2f = {
      enable = true;
      settings = {
        interactive = true;
        cue = true;
        # Root-owned, so code running as the user can't enroll its own key
        # (the default ~/.config/Yubico/u2f_keys is user-writable).
        authfile = "/etc/u2f-mappings";
        # u2f stays "sufficient" (no lockout if the key is lost), so require
        # the key's FIDO2 PIN: have + know, not just have.
        pinverification = 1;
      };
    };
    environment.etc."u2f-mappings" = {
      text = cfg.u2fMappings;
      mode = "0444";
    };

    # Smartcard mode
    services.pcscd.enable = true;
  };
}

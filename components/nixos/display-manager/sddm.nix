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

    # SDDM normally substacks `login`, where u2f and fprintd run before
    # pam_unix: a typed password then waits for the fingerprint/u2f timeout.
    # Reuse login's auth rules but move those two after the password check.
    # Typing your password logs in at once (and unlocks the keyring); an
    # empty password + Enter falls through to the fingerprint reader.
    security.pam.services.sddm.rules.auth = let
      loginAuth = config.security.pam.services.login.rules.auth;
      afterUnix = loginAuth.unix.order + 10;
    in
      lib.mkForce (lib.mapAttrs (
          name: rule: let
            # `name` is read-only (it comes from the key) and `args` is
            # regenerated from `settings`; copying either breaks the rule.
            r = builtins.removeAttrs rule ["name" "args"];
          in
            if name == "fprintd"
            then r // {order = afterUnix;}
            else if name == "u2f"
            then r // {order = afterUnix + 10;}
            else r
        )
        loginAuth);
  };
}

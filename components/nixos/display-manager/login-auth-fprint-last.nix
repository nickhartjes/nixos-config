# PAM auth rules for a graphical greeter, derived from `login`.
#
# `login` runs u2f and fprintd before pam_unix, so a typed password first
# waits for the fingerprint/u2f timeout. This reuses login's auth rules
# (keeping kwallet etc.) but moves those two after the password check:
# typing your password logs in at once and unlocks the keyring; an empty
# password falls through to the fingerprint reader.
config: let
  loginAuth = config.security.pam.services.login.rules.auth;
  afterUnix = loginAuth.unix.order + 10;
in
  builtins.mapAttrs (
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
  loginAuth

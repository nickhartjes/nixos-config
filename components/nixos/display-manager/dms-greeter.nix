{
  config,
  options,
  lib,
  pkgs,
  ...
}: let
  cfg = config.components.display.dms-greeter;
in {
  options.components.display.dms-greeter = {
    enable = lib.mkEnableOption "DMS greeter (greetd login screen styled like Dank Material Shell)";
    compositor = lib.mkOption {
      type = lib.types.str;
      default = "mango";
      description = "Compositor the greeter runs in (see programs.dms-greeter.compositor.name).";
    };
    configHome = lib.mkOption {
      type = lib.types.str;
      default = "/home/nh";
      description = "Home whose DMS settings, wallpaper and colours the greeter copies at startup.";
    };
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ../../../assets/wallpapers/artemis2-earthset.jpg;
      description = ''
        Greeter background. The desktop wallpaper is drawn by swaybg, not DMS,
        so DMS has no session.json for the greeter to take it from.
      '';
    };
  };

  # The dank-greeter module is only imported on framework-13; other hosts must
  # not define programs.dms-greeter (that would fail with "option does not exist").
  config = lib.optionalAttrs (options ? programs.dms-greeter) (lib.mkIf cfg.enable {
    programs.dms-greeter = {
      enable = true;
      compositor.name = cfg.compositor;
      # Without an explicit config Mango falls back to the missing
      # /etc/mango/config.toml and shows an error on the login screen.
      # DMS supplies the greeter startup command separately via mango -s.
      compositor.customConfig = lib.mkIf (cfg.compositor == "mango") ''
        xkb_rules_layout = us
        xkb_rules_options = caps:escape
        tap_to_click = 1
        monitor_rule = name:eDP-1,scale:1.5
      '';
      inherit (cfg) configHome;
      # Listed first: a real ~/.local/state/dms/session.json, if one ever
      # appears, is copied later and wins.
      configFiles = lib.mkBefore [
        (pkgs.writeText "session.json" (builtins.toJSON {wallpaperPath = "${cfg.wallpaper}";}))
      ];
    };

    # Password first, then fingerprint/u2f, same as login but reordered
    # (see login-auth-fprint-last.nix). kwallet comes along: its auth rule is
    # copied from login, and greetd's session stack includes login's.
    security.pam.services.greetd.rules.auth =
      lib.mkForce (import ./login-auth-fprint-last.nix config);
  });
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.system.tailscale;
in {
  options.components.system.tailscale = {
    enable = mkEnableOption "Enable Tailscale VPN";
    authKey = mkOption {
      type = types.str;
      default = "";
      description = "Tailscale auth key for automatic login (optional)";
    };
    hostname = mkOption {
      type = types.str;
      default = "";
      description = "Set the Tailscale hostname (optional)";
    };
    advertiseRoutes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of routes to advertise (optional)";
    };
    advertiseTags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of tags to advertise (optional)";
    };
    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Extra configuration for services.tailscale (advanced, optional)";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale =
      {
        enable = true;
        # authKey and hostname are not supported by the NixOS module as of 24.05
        # Set these via extraConfig if supported in the future
      }
      // cfg.extraConfig;

    # trayscale: maintained GTK4/libadwaita tray GUI for Tailscale.
    # Replaces the abandoned tailscale-systray, which busy-looped on a core.
    environment.systemPackages = with pkgs; [
      trayscale
    ];

    # Autostart hidden into the tray with the graphical session.
    systemd.user.services.trayscale = {
      description = "Trayscale (Tailscale tray)";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${pkgs.trayscale}/bin/trayscale --hide-window";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}

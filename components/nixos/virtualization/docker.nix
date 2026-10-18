{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.virtualization.docker;

  # Default bind address for published ports, but only on the default docker0
  # bridge: compose networks ignore it, so it is not the LAN guard (see
  # DOCKER-USER below).
  daemonSettings.ip = "127.0.0.1";
in {
  options.components.virtualization.docker = {
    enable = mkEnableOption "enable docker";
    # The docker group is root without sudo. Workstations run a per-user
    # daemon instead; servers keep the system daemon for doco-cd and runners.
    rootless = mkEnableOption "run docker rootless (per-user daemon, no docker group)";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      networking.extraHosts = ''
        127.0.0.1 host.docker.internal
      '';
      environment.systemPackages = with pkgs; [
        docker-compose
      ];
    }

    (mkIf (!cfg.rootless) {
      virtualisation.docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [
            "--filter=until=24h"
            "--filter=label!=important"
          ];
        };
        daemon.settings = daemonSettings;
      };
      # Not br-+: containers on compose networks get no blanket access to host
      # ports. docker0 stays for host.docker.internal.
      networking.firewall.trustedInterfaces = ["docker0"];

      # Docker DNATs published ports in PREROUTING, before nixos-fw sees them,
      # so a bare `ports: "5432:5432"` in any compose file is open to the LAN.
      # DOCKER-USER is the chain Docker evaluates first in FORWARD and never
      # flushes: drop new connections to containers unless they come from a
      # container bridge, loopback or the tailnet. Replies and outbound
      # container traffic (cloudflared, pulls) are untouched.
      networking.firewall.extraCommands = ''
        ip46tables -N DOCKER-USER 2>/dev/null || true
        ip46tables -F DOCKER-USER
        ip46tables -A DOCKER-USER -m conntrack --ctstate RELATED,ESTABLISHED -j RETURN
        ip46tables -A DOCKER-USER -i docker0 -j RETURN
        ip46tables -A DOCKER-USER -i br+ -j RETURN
        ip46tables -A DOCKER-USER -i lo -j RETURN
        ip46tables -A DOCKER-USER -i tailscale0 -j RETURN
        ip46tables -A DOCKER-USER -m conntrack --ctstate NEW -j DROP
        ip46tables -A DOCKER-USER -j RETURN
      '';
      # Leave the chain in place (Docker's FORWARD jump points at it) but empty,
      # matching what Docker itself creates.
      networking.firewall.extraStopCommands = ''
        ip46tables -F DOCKER-USER 2>/dev/null || true
      '';

      assertions = [
        {
          assertion = !config.networking.nftables.enable;
          message = "components.virtualization.docker: the DOCKER-USER guard is iptables-only.";
        }
      ];
    })

    (mkIf cfg.rootless {
      virtualisation.docker.rootless = {
        enable = true;
        # Exports DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock.
        setSocketVariable = true;
        daemon.settings = daemonSettings;
      };
    })
  ]);
}

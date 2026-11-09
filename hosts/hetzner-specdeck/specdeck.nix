{
  config,
  pkgs,
  lib,
  ...
}: let
  # SpecDeck's sharing service (signalling, TURN credentials and the web
  # viewer), next to coturn in configuration.nix. It runs the release image
  # from ghcr.io in podman, and podman-auto-update pulls each new release.
  #
  # The service listens on loopback only and is published as
  # https://specdeck.hartj.es through a remote-managed Cloudflare tunnel
  # (route specdeck.hartj.es -> http://localhost:8080 in the dashboard), so no
  # TCP port is opened. Apps connect to wss://specdeck.hartj.es/signal.
  # turn.hartj.es is a DNS-only record for this host.
  #
  # Image: the floating major tag, so every 1.x release is picked up.
  image = "ghcr.io/nickhartjes/specdeck-server:1";
  port = 8080;
  turnPort = 3478;
  envDir = "/run/specdeck-env";

  # Which release is running: the image's OCI version label, its digest, and
  # the version the registry has under the tag.
  specdeck-version = pkgs.writeShellScriptBin "specdeck-version" ''
    set -euo pipefail
    podman=${lib.getExe config.virtualisation.podman.package}
    echo "running: $($podman inspect specdeck-server --format '{{index .Config.Labels "org.opencontainers.image.version"}} {{.ImageDigest}}')"
    echo "started: $($podman inspect specdeck-server --format '{{.State.StartedAt}}')"
    $podman auto-update --dry-run --format '{{.Unit}}  {{.Image}}  update available: {{.Updated}}'
  '';
in {
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.specdeck-server = {
    inherit image;
    # Only reachable through cloudflared on this host.
    ports = ["127.0.0.1:${toString port}:8080"];
    environment = {
      SPECDECK_TURN_URLS = "turn:turn.hartj.es:${toString turnPort}?transport=udp";
      # cloudflared is the one proxy in front; it sets X-Forwarded-For.
      SPECDECK_TRUSTED_PROXIES = "1";
      RUST_LOG = "info";
    };
    # SPECDECK_TURN_SECRET, written by specdeck-server-env below.
    environmentFiles = ["${envDir}/turn.env"];
    # podman-auto-update checks the registry for a new digest under the tag,
    # pulls it and restarts the unit; a unit that fails to start is rolled
    # back to the previous image.
    labels."io.containers.autoupdate" = "registry";
    extraOptions = [
      "--cap-drop=all"
      "--security-opt=no-new-privileges"
      "--read-only"
    ];
  };

  # The binary reads the TURN secret from the environment only, and podman
  # wants it as an env file. Derived at boot from the agenix secret coturn
  # also uses, so there is one secret to rotate; tmpfs, root only.
  systemd.services.specdeck-server-env = {
    description = "SpecDeck server env file from the TURN secret";
    before = ["podman-specdeck-server.service"];
    requiredBy = ["podman-specdeck-server.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "specdeck-env";
      RuntimeDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      printf 'SPECDECK_TURN_SECRET=%s\n' \
        "$(< ${config.age.secrets."hetzner-specdeck/specdeck-turn-secret".path})" \
        > ${envDir}/turn.env
    '';
  };

  # The podman package ships podman-auto-update.{service,timer} (daily);
  # enable it and check every 15 minutes, so a release lands within ~15 min.
  systemd.timers.podman-auto-update = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = ["" "*:0/15"];
      RandomizedDelaySec = "1min";
    };
  };

  environment.systemPackages = [specdeck-version];

  # Remote-managed tunnel: its routes live in the Cloudflare dashboard, so this
  # only needs the token. services.cloudflared only supports locally-managed
  # tunnels (credentials file), hence a plain unit.
  systemd.services.cloudflared-specdeck = {
    description = "Cloudflare tunnel for SpecDeck";
    after = ["network-online.target" "podman-specdeck-server.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.cloudflared} tunnel --no-autoupdate run --token-file %d/tunnel-token";
      LoadCredential = "tunnel-token:${config.age.secrets."hetzner-specdeck/specdeck-tunnel-token".path}";
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = 5;
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectHome = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK"];
    };
  };
}

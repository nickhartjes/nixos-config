{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # SpecDeck's signalling service (matchmaking + TURN credentials), next to
  # coturn in configuration.nix.
  #
  # Signalling listens on loopback only and is published as
  # https://specdeck.hartj.es through a remote-managed Cloudflare tunnel
  # (route specdeck.hartj.es -> http://localhost:8080 in the dashboard), so no
  # TCP port is opened. Apps connect to wss://specdeck.hartj.es/signal.
  # turn.hartj.es is a DNS-only record for this host.
  signallingPort = 8080;
  turnPort = 3478;
  signalling = pkgs.callPackage ../../pkgs/specdeck-signalling {
    src = inputs.specdeck;
    inherit (inputs.specdeck.packages.${pkgs.stdenv.hostPlatform.system}.specdeck) pnpmDeps;
  };
in {
  systemd.services.specdeck-signalling = {
    description = "SpecDeck signalling service";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      SPECDECK_LISTEN = "127.0.0.1:${toString signallingPort}";
      SPECDECK_TURN_URLS = "turn:turn.hartj.es:${toString turnPort}?transport=udp";
      # cloudflared is the one proxy in front; it sets X-Forwarded-For.
      SPECDECK_TRUSTED_PROXIES = "1";
      RUST_LOG = "info";
    };
    # The binary reads the TURN secret from the environment only.
    script = ''
      SPECDECK_TURN_SECRET="$(< "$CREDENTIALS_DIRECTORY/turn-secret")"
      export SPECDECK_TURN_SECRET
      exec ${lib.getExe signalling}
    '';
    serviceConfig = {
      LoadCredential = "turn-secret:${config.age.secrets."hetzner-specdeck/specdeck-turn-secret".path}";
      DynamicUser = true;
      Restart = "on-failure";
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = ["@system-service" "~@privileged"];
    };
  };

  # Remote-managed tunnel: its routes live in the Cloudflare dashboard, so this
  # only needs the token. services.cloudflared only supports locally-managed
  # tunnels (credentials file), hence a plain unit.
  systemd.services.cloudflared-specdeck = {
    description = "Cloudflare tunnel for SpecDeck signalling";
    after = ["network-online.target" "specdeck-signalling.service"];
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

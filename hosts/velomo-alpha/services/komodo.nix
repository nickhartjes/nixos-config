{
  config,
  pkgs,
  lib,
  ...
}: let
  komodoDataRoot = "/var/lib/komodo";
  # Image tags pinned to a major version. Verify the current stable major
  # at https://github.com/moghtech/komodo/pkgs/container/komodo-core before
  # promoting velomo-alpha to "in use".
  komodoImageTag = "1";
in {
  # ---- State directories ----
  systemd.tmpfiles.rules = [
    "d ${komodoDataRoot} 0750 root root - -"
    "d ${komodoDataRoot}/mongo 0750 root root - -"
    "d ${komodoDataRoot}/core 0750 root root - -"
    "d ${komodoDataRoot}/periphery 0750 root root - -"
    "d /opt/stacks 0755 root root - -"
  ];

  # ---- Dedicated docker network so the three containers can resolve each
  #      other by name without exposing extra host ports ----
  systemd.services.init-komodo-network = {
    description = "Create internal komodo docker network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect komodo >/dev/null 2>&1 \
        || ${pkgs.docker}/bin/docker network create komodo
    '';
  };

  # ---- Containers ----
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      mongo = {
        image = "mongo:7";
        autoStart = true;
        extraOptions = ["--network=komodo"];
        environmentFiles = [
          config.age.secrets."velomo-alpha/komodo-db".path
        ];
        volumes = [
          "${komodoDataRoot}/mongo:/data/db"
        ];
      };

      komodo-core = {
        image = "ghcr.io/moghtech/komodo-core:${komodoImageTag}";
        autoStart = true;
        dependsOn = ["mongo"];
        extraOptions = ["--network=komodo" "--init"];
        ports = ["9120:9120"];
        environment = {
          KOMODO_HOST = "http://velomo-alpha:9120";
          KOMODO_DATABASE_ADDRESS = "mongo:27017";
          KOMODO_FIRST_SERVER = "http://komodo-periphery:8120";
          # Enable username/password login. First user to sign up via the UI
          # becomes admin automatically.
          KOMODO_LOCAL_AUTH = "true";
        };
        environmentFiles = [
          config.age.secrets."velomo-alpha/komodo-db".path
          # Exports KOMODO_PASSKEY and KOMODO_JWT_SECRET.
          # Database credentials (KOMODO_DATABASE_USERNAME / KOMODO_DATABASE_PASSWORD)
          # come from the komodo-db env file above.
          config.age.secrets."velomo-alpha/komodo-core-env".path
        ];
        volumes = [
          "${komodoDataRoot}/core:/config"
          # TOML provider config (git_provider / docker_registry entries).
          # Env vars still take precedence; this file only carries things that
          # have no env-var equivalent.
          "${config.age.secrets."velomo-alpha/komodo-core-config".path}:/config/config.toml:ro"
        ];
      };

      komodo-periphery = {
        image = "ghcr.io/moghtech/komodo-periphery:${komodoImageTag}";
        autoStart = true;
        extraOptions = ["--network=komodo" "--init"];
        ports = ["127.0.0.1:8120:8120"];
        environment = {
          PERIPHERY_PORT = "8120";
          # Speak plain HTTP on the internal docker network. Core hits
          # komodo-periphery via http://komodo-periphery:8120 — see
          # KOMODO_FIRST_SERVER on komodo-core.
          PERIPHERY_SSL_ENABLED = "false";
        };
        environmentFiles = [
          # Exports PERIPHERY_PASSKEYS (same value as KOMODO_PASSKEY on core).
          config.age.secrets."velomo-alpha/komodo-passkey-env".path
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "${komodoDataRoot}/periphery:/etc/komodo"
          "/opt/stacks:/opt/stacks"
        ];
      };
    };
  };

  # ---- Ensure containers wait for the komodo network to exist ----
  systemd.services.docker-mongo.after = ["init-komodo-network.service"];
  systemd.services.docker-mongo.requires = ["init-komodo-network.service"];
  systemd.services.docker-komodo-core.after = ["init-komodo-network.service"];
  systemd.services.docker-komodo-core.requires = ["init-komodo-network.service"];
  systemd.services.docker-komodo-periphery.after = ["init-komodo-network.service"];
  systemd.services.docker-komodo-periphery.requires = ["init-komodo-network.service"];
}

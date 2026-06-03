{
  config,
  pkgs,
  lib,
  ...
}: let
  # doco-cd hardcodes /data internally (cmd/doco-cd/main.go: dataPath = "/data").
  # The path must exist on the host with the SAME name so that relative volume
  # paths in deployed compose files (e.g. ./beszel_data) resolve consistently
  # between doco-cd's container view and the docker daemon's host view.
  dataDir = "/data";
in {
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root - -"
  ];

  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers.doco-cd = {
    image = "ghcr.io/kimdre/doco-cd:0.89.1";
    autoStart = true;
    extraOptions = ["--init"];

    # No host port exposure — running polling-only (GitHub can't reach a LAN
    # host for webhooks anyway). Healthcheck still runs inside the container.
    environment = {
      TZ = "Europe/Amsterdam";
      LOG_LEVEL = "info";
      GIT_ACCESS_TOKEN_FILE = "/run/doco/git-token";
      # Point the docker SDK at the agenix-decrypted registry-auth config
      # so doco-cd can authenticate to zot (registry.velomo.nl + the
      # 127.0.0.1:5000 loopback) when pulling images. The docker SDK
      # reads `$DOCKER_CONFIG/config.json`.
      DOCKER_CONFIG = "/run/doco/docker";
      POLL_CONFIG = ''
        - url: https://github.com/Dealdodo/scraper.git
          reference: main
          interval: 180
        - url: https://github.com/Dealdodo/frontend.git
          reference: main
          interval: 180
      '';
    };

    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "${dataDir}:${dataDir}"
      # Read-only mount of the agenix-decrypted PAT into a stable in-container path
      "${config.age.secrets."velomo-alpha/doco-git-token".path}:/run/doco/git-token:ro"
      # Docker registry auth (used by the docker SDK in doco-cd when
      # pulling private images from registry.velomo.nl / 127.0.0.1:5000).
      "${config.age.secrets."velomo-alpha/doco-docker-config.json".path}:/run/doco/docker/config.json:ro"
      # Expose all agenix-decrypted secrets to doco-cd so deployed compose
      # stacks can reference them via env_file: /run/agenix/<host>/<name>
      # without doco-cd needing to know about each one individually.
      "/run/agenix:/run/agenix:ro"
    ];
  };
}

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
      TZ = "Europe/Berlin";
      LOG_LEVEL = "info";
      GIT_ACCESS_TOKEN_FILE = "/run/doco/git-token";
      POLL_CONFIG = ''
        - url: https://github.com/Dealdodo/scraper.git
          reference: main
          interval: 180
      '';
    };

    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock"
      "${dataDir}:${dataDir}"
      # Read-only mount of the agenix-decrypted PAT into a stable in-container path
      "${config.age.secrets."velomo-alpha/doco-git-token".path}:/run/doco/git-token:ro"
    ];
  };
}

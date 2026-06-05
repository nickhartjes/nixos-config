{
  config,
  pkgs,
  ...
}: {
  # github-runner 2.334.0 no longer provides a working lib/externals/node20,
  # so Node-20-pinned JS actions (e.g. docker/setup-buildx-action@v3) fail to
  # launch with "node20/bin/node: No such file or directory" while Node-24
  # actions (actions/checkout@v6) run fine. We force all JS actions onto the
  # bundled Node 24 via FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 (set per runner in
  # serviceOverrides below) — the opt-in GitHub documents ahead of the June
  # 2026 Node-20 removal. permittedInsecurePackages is kept harmless in case
  # anything still resolves node20.
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-20.20.2"
    "nodejs-slim-20.20.2"
  ];


  # Self-hosted GitHub Actions runner for the Dealdodo/scraper repo.
  #
  # Why: Cloudflare's 100 MB per-request body limit rejects Spring Boot
  # dependency layers when buildx pushes to registry.velomo.nl. Running
  # the publish job on velomo-alpha itself lets it push to 127.0.0.1:5000
  # (zot's loopback bind), bypassing Cloudflare entirely.
  #
  # The registration token in tokenFile is consumed once on first
  # registration; after that the runner persists its own credentials
  # under /var/lib/github-runners/scraper/ and the token can expire.
  # To re-register from scratch (e.g. after the data dir is wiped),
  # generate a fresh token via:
  #   gh api -X POST /repos/Dealdodo/scraper/actions/runners/registration-token --jq .token
  # then re-encrypt secrets/velomo-alpha/github-runner-token.age.
  services.github-runners.scraper = {
    enable = true;
    url = "https://github.com/Dealdodo/scraper";
    tokenFile = config.age.secrets."velomo-alpha/github-runner-token".path;

    # Workflows target this runner with `runs-on: [self-hosted, velomo-alpha]`
    # (or just `self-hosted`). The labels are advisory — defaults already
    # include "self-hosted", "Linux", and the arch.
    extraLabels = ["velomo-alpha" "scraper"];

    # Tell GitHub to replace an existing runner with the same name if one
    # is already registered. Lets us re-register cleanly without manual
    # cleanup in the GH UI.
    replace = true;

    # Tools the workflows need on PATH. docker/buildx/git are non-optional;
    # the rest are convenience.
    extraPackages = with pkgs; [
      docker
      docker-buildx
      git
      gh
      gnumake
      jq
      coreutils
      gnused
      gnugrep
    ];

    # The systemd unit uses a dynamic user, which means there's no
    # /etc/passwd entry to add to the docker group. Grant docker socket
    # access via SupplementaryGroups on the unit instead.
    serviceOverrides = {
      SupplementaryGroups = ["docker"];
      # Run JS actions on Node 24; the runner's node20 externals are missing.
      Environment = ["FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true"];
    };
  };

  # Self-hosted GitHub Actions runner for the Dealdodo/frontend repo.
  #
  # Why a second runner (not org-scoped): velomo-alpha's existing runner is
  # repo-scoped to Dealdodo/scraper. Per-repo runners require one registration
  # token per repo, so the simplest path to handle the frontend repo is a
  # second runner service with its own agenix secret.
  #
  # The registration token in tokenFile is consumed once on first
  # registration; after that the runner persists its own credentials
  # under /var/lib/github-runners/frontend/ and the token can expire.
  # To re-register from scratch (e.g. after the data dir is wiped),
  # generate a fresh token via:
  #   gh api -X POST /repos/Dealdodo/frontend/actions/runners/registration-token --jq .token
  # then re-encrypt secrets/velomo-alpha/frontend-runner-token.age.
  services.github-runners.frontend = {
    enable = true;
    url = "https://github.com/Dealdodo/frontend";
    tokenFile = config.age.secrets."velomo-alpha/frontend-runner-token".path;

    # Workflow targets this runner with `runs-on: [self-hosted, velomo-alpha]`.
    # The "frontend" label is advisory and lets future workflows narrow targeting.
    extraLabels = ["velomo-alpha" "frontend"];

    # Cleanly re-register if a runner with the same name already exists.
    replace = true;

    # Tools the frontend's publish job needs on PATH.
    extraPackages = with pkgs; [
      docker
      docker-buildx
      git
      gh
      jq
      coreutils
      gnused
      gnugrep
    ];

    # The systemd unit uses a dynamic user — grant docker socket access via
    # SupplementaryGroups instead of chowning.
    serviceOverrides = {
      SupplementaryGroups = ["docker"];
      # Run JS actions on Node 24; the runner's node20 externals are missing.
      Environment = ["FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true"];
    };
  };
}

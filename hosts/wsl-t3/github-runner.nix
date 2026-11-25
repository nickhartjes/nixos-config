{
  config,
  lib,
  pkgs,
  ...
}: let
  name = "velomo-rebuild";
  # On disk, kept between jobs and restarts: Gradle's caches and the tools mise installs. The work directory itself
  # stays the module's default under /run, cleaned on every start.
  cache = "/var/cache/github-runner-${name}";
in {
  # Self-hosted GitHub Actions runner for the Dealdodo/velomo-rebuild repo.
  #
  # Why: CI on GitHub's hosted runners took 37 to 53 minutes per run and stops whenever the organisation's Actions
  # billing does. This machine has 24 cores, keeps Gradle's and Docker's caches between runs, and builds in about a
  # fifth of the time.
  #
  # The job runs as the module's dynamic user with ProtectHome, so it cannot read /home (and the private holdout kept
  # there); it reaches Docker for Testcontainers through the docker group.
  #
  # The registration token in tokenFile is consumed once on first registration; after that the runner persists its
  # own credentials under /var/lib/github-runner/velomo-rebuild/ and the token can expire. To re-register from scratch
  # (e.g. after the state directory is wiped), generate a fresh token via:
  #   gh api -X POST /repos/Dealdodo/velomo-rebuild/actions/runners/registration-token --jq .token
  # then re-encrypt secrets/wsl-t3/velomo-rebuild-runner-token.age.
  age.secrets."wsl-t3/velomo-rebuild-runner-token" = {
    file = ../../secrets/wsl-t3/velomo-rebuild-runner-token.age;
    # The runner module copies tokenFile in a root ExecStartPre ("+"), so root may own it.
    mode = "400";
  };

  services.github-runners.${name} = {
    enable = true;
    url = "https://github.com/Dealdodo/velomo-rebuild";
    tokenFile = config.age.secrets."wsl-t3/velomo-rebuild-runner-token".path;
    # Workflows target this runner with `runs-on: [self-hosted, wsl-t3]`.
    extraLabels = ["wsl-t3" name];
    replace = true;

    # The build brings its own tools through mise (Java, hk and the linters); these are what the workflow and mise
    # need around them.
    extraPackages = with pkgs; [
      bash
      docker
      git
      # ldd: mise-action uses it to tell glibc from musl.
      glibc.bin
      unzip
      gnutar
      gzip
      xz
      curl
      coreutils
      gnused
      gnugrep
      findutils
      which
    ];

    serviceOverrides = {
      SupplementaryGroups = ["docker"];
      CacheDirectory = ["github-runner-${name}"];
      # systemd mounts a dynamic user's cache directory noexec; mise's tools and Gradle's native libraries run from it.
      ExecPaths = ["/var/cache/private/github-runner-${name}"];
      Environment = [
        # Run JS actions on Node 24; the runner's node20 externals are missing (as on velomo-alpha).
        "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true"
        # mise's downloaded tools are generic Linux binaries: run them through nix-ld, as in a login shell. A
        # service does not read /etc/set-environment, so the variables are set here.
        "NIX_LD=${config.environment.variables.NIX_LD}"
        "NIX_LD_LIBRARY_PATH=${config.environment.variables.NIX_LD_LIBRARY_PATH}"
        "GRADLE_USER_HOME=${cache}/gradle"
        # Tools that cache under ~/.cache (pkl for hk's config) would reach for /.cache, read-only here.
        "XDG_CACHE_HOME=${cache}/xdg"
        "MISE_DATA_DIR=${cache}/mise"
        "MISE_CACHE_DIR=${cache}/mise-cache"
        # Precompiled Node and Python through nix-ld, as nh's mise config has it, rather than compiling from source.
        "MISE_NODE_COMPILE=false"
        "MISE_PYTHON_COMPILE=false"
      ];
    };
  };
}

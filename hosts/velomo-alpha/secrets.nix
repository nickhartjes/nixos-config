{config, ...}: {
  age.secrets = {
    "velomo-alpha/tailscale-authkey" = {
      file = ../../secrets/velomo-alpha/tailscale-authkey.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/doco-git-token" = {
      file = ../../secrets/velomo-alpha/doco-git-token.age;
      owner = "root";
      # World-readable so the doco-cd container process (non-root inside) can read it.
      mode = "444";
    };
    # htpasswd for zot registry (read by zot container; doco-cd container
    # itself only needs to invoke compose, not read this file).
    "velomo-alpha/zot-htpasswd" = {
      file = ../../secrets/velomo-alpha/zot-htpasswd.age;
      owner = "root";
      mode = "444";
    };
    # Env file containing CLOUDFLARED_TUNNEL_TOKEN=... for the registry tunnel.
    # Loaded via `env_file:` in zot.compose.yaml; doco-cd's compose invocation
    # reads it from /run/agenix (bind-mounted into doco-cd by services/doco.nix).
    "velomo-alpha/cloudflared-registry-token.env" = {
      file = ../../secrets/velomo-alpha/cloudflared-registry-token.env.age;
      owner = "root";
      mode = "444";
    };
    # One-time registration token for the self-hosted GitHub Actions runner.
    # Generate fresh via:
    #   gh api -X POST /repos/Dealdodo/scraper/actions/runners/registration-token --jq .token
    # Token expires ~1h after generation but is consumed once on first
    # service start; after that the runner uses persisted credentials.
    "velomo-alpha/github-runner-token" = {
      file = ../../secrets/velomo-alpha/github-runner-token.age;
      owner = "root";
      # World-readable (within /run/agenix/, which is root-protected at the
      # directory level). The github-runner service uses a systemd dynamic
      # user — we can't chown to it because the UID isn't allocated until
      # the service starts.
      mode = "444";
    };
    # Env-file for the scraper app stack: DB_PASSWORD, MEILI_MASTER_KEY,
    # ANTHROPIC_API_KEY, plus placeholder Phase-2 vars (RUSTFS_*, BACKUP_*,
    # CLOUDFLARED_IMAGES_TUNNEL_TOKEN). Loaded by doco-cd via the
    # .doco-cd.yaml env_files entry; doco-cd mounts /run/agenix in via
    # services/doco.nix so the absolute path works inside its container.
    "velomo-alpha/scraper-app.env" = {
      file = ../../secrets/velomo-alpha/scraper-app.env.age;
      owner = "root";
      mode = "444";
    };
    # docker config.json for doco-cd to authenticate to zot when pulling
    # registry.velomo.nl/velomo/scraper. Mounted into the doco-cd
    # container as the docker SDK's config file (see services/doco.nix).
    "velomo-alpha/doco-docker-config.json" = {
      file = ../../secrets/velomo-alpha/doco-docker-config.json.age;
      owner = "root";
      mode = "444";
    };
  };
}

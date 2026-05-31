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
    # TUNNEL_TOKEN for the single public-ingress tunnel (reuses the registry
    # tunnel's token) that feeds the Caddy reverse proxy in the auth stack.
    # Loaded via `env_file:` in infra/compose/auth.compose.yaml; doco-cd reads
    # it from /run/agenix (bind-mounted into doco-cd by services/doco.nix).
    "velomo-alpha/cloudflared-main-token.env" = {
      file = ../../secrets/velomo-alpha/cloudflared-main-token.env.age;
      owner = "root";
      mode = "444";
    };
    # Authelia core secrets: AUTHELIA_JWT_SECRET, AUTHELIA_SESSION_SECRET,
    # AUTHELIA_STORAGE_ENCRYPTION_KEY. Loaded via `env_file:` by the authelia
    # service in infra/compose/auth.compose.yaml.
    "velomo-alpha/authelia-secrets.env" = {
      file = ../../secrets/velomo-alpha/authelia-secrets.env.age;
      owner = "root";
      mode = "444";
    };
    # Authelia file-backed user store, mounted into the authelia container at
    # /config/users_database.yml (see infra/compose/auth.compose.yaml). 444 so
    # the non-root authelia container user can read it; /run/agenix is itself
    # root-only at the directory level, so it isn't truly world-accessible.
    "velomo-alpha/authelia-users.yml" = {
      file = ../../secrets/velomo-alpha/authelia-users.yml.age;
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
    # Env-file for the observability (LGTM) stack: OBS_RUSTFS_ROOT_USER/PASSWORD,
    # OBS_RUSTFS_ACCESS_KEY/SECRET_KEY, GF_SECURITY_ADMIN_PASSWORD. Loaded by
    # doco-cd via the observability stack's env_files entry in .doco-cd.yaml;
    # doco-cd reads it from /run/agenix (bind-mounted via services/doco.nix).
    "velomo-alpha/observability.env" = {
      file = ../../secrets/velomo-alpha/observability.env.age;
      owner = "root";
      mode = "444";
    };
    # Slack incoming-webhook URL (bare URL, no key) for Alertmanager. Bind-mounted
    # into the alertmanager container at /etc/alertmanager/slack-url and read via
    # `slack_api_url_file` in infra/observability/alertmanager.prod.yaml.
    "velomo-alpha/alertmanager-slack-url" = {
      file = ../../secrets/velomo-alpha/alertmanager-slack-url.age;
      owner = "root";
      mode = "444";
    };
  };
}

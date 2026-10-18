{config, ...}: {
  # /run/agenix.d is 0751, so each file's own mode decides who can read it.
  # doco-cd and zot run as root in their containers; compose env_files are
  # read by doco-cd. So 0400 root is enough for almost everything.
  users.groups.velomo-secrets.gid = 990;

  age.secrets = {
    "velomo-alpha/tailscale-authkey" = {
      file = ../../secrets/velomo-alpha/tailscale-authkey.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/doco-git-token" = {
      file = ../../secrets/velomo-alpha/doco-git-token.age;
      owner = "root";
      mode = "400";
    };
    # htpasswd for zot registry (bind-mounted into the zot container, which
    # runs as root).
    "velomo-alpha/zot-htpasswd" = {
      file = ../../secrets/velomo-alpha/zot-htpasswd.age;
      owner = "root";
      mode = "400";
    };
    # Env file containing CLOUDFLARED_TUNNEL_TOKEN=... for the registry tunnel.
    # Loaded via `env_file:` in zot.compose.yaml; doco-cd's compose invocation
    # reads it from /run/agenix (bind-mounted into doco-cd by services/doco.nix).
    "velomo-alpha/cloudflared-registry-token.env" = {
      file = ../../secrets/velomo-alpha/cloudflared-registry-token.env.age;
      owner = "root";
      mode = "400";
    };
    # TUNNEL_TOKEN for the single public-ingress tunnel (reuses the registry
    # tunnel's token) that feeds the Caddy reverse proxy in the auth stack.
    # Loaded via `env_file:` in infra/compose/auth.compose.yaml; doco-cd reads
    # it from /run/agenix (bind-mounted into doco-cd by services/doco.nix).
    "velomo-alpha/cloudflared-main-token.env" = {
      file = ../../secrets/velomo-alpha/cloudflared-main-token.env.age;
      owner = "root";
      mode = "400";
    };
    # One-time registration token for the self-hosted GitHub Actions runner.
    # Generate fresh via:
    #   gh api -X POST /repos/Dealdodo/scraper/actions/runners/registration-token --jq .token
    # Token expires ~1h after generation but is consumed once on first
    # service start; after that the runner uses persisted credentials.
    "velomo-alpha/github-runner-token" = {
      file = ../../secrets/velomo-alpha/github-runner-token.age;
      owner = "root";
      # The runner module copies tokenFile in a root ExecStartPre ("+"), so
      # the dynamic user never reads it directly.
      mode = "400";
    };
    # Env-file for the scraper app stack: DB_PASSWORD, MEILI_MASTER_KEY,
    # ANTHROPIC_API_KEY, plus placeholder Phase-2 vars (RUSTFS_*, BACKUP_*,
    # CLOUDFLARED_IMAGES_TUNNEL_TOKEN). Loaded by doco-cd via the
    # .doco-cd.yaml env_files entry; doco-cd mounts /run/agenix in via
    # services/doco.nix so the absolute path works inside its container.
    "velomo-alpha/scraper-app.env" = {
      file = ../../secrets/velomo-alpha/scraper-app.env.age;
      owner = "root";
      mode = "400";
    };
    # docker config.json for doco-cd to authenticate to zot when pulling
    # registry.velomo.nl/velomo/scraper. Mounted into the doco-cd
    # container as the docker SDK's config file (see services/doco.nix).
    "velomo-alpha/doco-docker-config.json" = {
      file = ../../secrets/velomo-alpha/doco-docker-config.json.age;
      owner = "root";
      mode = "400";
    };
    # Env-file for the observability (LGTM) stack: OBS_RUSTFS_ROOT_USER/PASSWORD,
    # OBS_RUSTFS_ACCESS_KEY/SECRET_KEY, GF_SECURITY_ADMIN_PASSWORD. Loaded by
    # doco-cd via the observability stack's env_files entry in .doco-cd.yaml;
    # doco-cd reads it from /run/agenix (bind-mounted via services/doco.nix).
    "velomo-alpha/observability.env" = {
      file = ../../secrets/velomo-alpha/observability.env.age;
      owner = "root";
      mode = "400";
    };
    # Slack incoming-webhook URL (bare URL, no key) for Alertmanager. Bind-mounted
    # into the alertmanager container at /etc/alertmanager/slack-url and read via
    # `slack_api_url_file` in infra/observability/alertmanager.prod.yaml.
    # The alertmanager image runs as nobody (65534, same uid on the host).
    "velomo-alpha/alertmanager-slack-url" = {
      file = ../../secrets/velomo-alpha/alertmanager-slack-url.age;
      owner = "nobody";
      mode = "400";
    };
    # GitHub Actions runner registration token for the Dealdodo/frontend repo.
    # Consumed once on first registration by services.github-runners.frontend.
    # Copied in by the runner module's root ExecStartPre, like the scraper token.
    "velomo-alpha/frontend-runner-token" = {
      file = ../../secrets/velomo-alpha/frontend-runner-token.age;
      owner = "root";
      mode = "400";
    };
    # Build-time env for the frontend CI publish job. Read by the workflow's
    # "Load build env from agenix" step which sources it into $GITHUB_ENV.
    # The job step runs as the runner's dynamic user, which gets the
    # velomo-secrets group via SupplementaryGroups (services/github-runner.nix).
    "velomo-alpha/frontend-build.env" = {
      file = ../../secrets/velomo-alpha/frontend-build.env.age;
      owner = "root";
      group = "velomo-secrets";
      mode = "440";
    };
    # Runtime env for the frontend stack (Astro app + Fider feedback board +
    # its dedicated Postgres). Single env file shared by all three services
    # in docker-compose.prod.yml. Loaded via env_files in .doco-cd.yaml;
    # doco-cd reads it from /run/agenix (bind-mounted via services/doco.nix).
    "velomo-alpha/frontend-app.env" = {
      file = ../../secrets/velomo-alpha/frontend-app.env.age;
      owner = "root";
      mode = "400";
    };
    # Runtime env for the Logto identity provider stack (logto, logto-db,
    # oauth2-proxy). Contains: LOGTO_DB_PASSWORD, LOGTO_ENDPOINT,
    # LOGTO_ADMIN_ENDPOINT, OAUTH2_PROXY_CLIENT_ID, OAUTH2_PROXY_CLIENT_SECRET,
    # OAUTH2_PROXY_REDIRECT_URL, OAUTH2_PROXY_COOKIE_SECRET, and the shared
    # BACKUP_S3_* vars (same bucket as scraper, logto-db uses /logto-backups path).
    # Loaded alongside frontend-app.env via env_files in .doco-cd.yaml.
    # Create/edit: cd nixos-config && agenix -e secrets/velomo-alpha/logto-app.env.age
    "velomo-alpha/logto-app.env" = {
      file = ../../secrets/velomo-alpha/logto-app.env.age;
      owner = "root";
      mode = "400";
    };
  };
}

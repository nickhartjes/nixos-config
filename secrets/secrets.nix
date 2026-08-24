let
  # Systems
  framework-13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es";
  framework-13-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es";
  velomo-alpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeRh4DdyxTgGmDYgAaYY8yT5M0MSbRz1yGPi4P/jzWS root@velomo-alpha";
  n100-nanoclaw = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDtWggZjgd5P93BkTrNUwaeyattrF4ZUgRvHC36fJNOF root@n100-nanoclaw";

  # framework-13's SSH *host* key (/etc/ssh/ssh_host_ed25519_key.pub). This is
  # the identity agenix uses at activation time -- it lives on /, which is
  # mounted before activation runs. The framework-13/-2 keys above are nh's
  # *user* keys under /home, which is NOT mounted yet at that point (only
  # /persist and /var/log are neededForBoot, see hosts/framework-13/disko-config.nix),
  # so they can decrypt for `agenix -e` but never at boot.
  framework-13-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF2qLIp0K5IhC75m7efjriiBqCrwrGFsq/tRC0NRJ3T root@framework-13";

  systems = [framework-13-host];
  velomoSystems = [velomo-alpha];
  nanoclawSystems = [n100-nanoclaw];
in {
  "secret1.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  # Grafana service-account token (export GRAFANA_SA_TOKEN=...) for the Velomo
  # prod observability stack's MCP. Decrypted on framework-13 to nh's home so
  # zsh can source it (see hosts/framework-13/secrets.nix + users/nh.nix).
  "framework-13/grafana-sa-token.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  # Hevy API key (export HEVY_API_KEY=...) for the hevy MCP in the NH Obsidian
  # vault's .mcp.json. Same flow as the grafana token: decrypted to
  # ~/.config/hevy-mcp.env and sourced by zsh (users/nh.nix).
  "framework-13/hevy-api-key.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  "nh/ssh-framework-13.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  "nh/ssh-framework-13.pub.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  "nh/gpg-private-key.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  "nh/gpg-public-key.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  "velomo-alpha/tailscale-authkey.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/doco-git-token.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/zot-htpasswd.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/cloudflared-registry-token.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  # Single public-ingress tunnel (reuses the registry tunnel token) feeding Caddy.
  "velomo-alpha/cloudflared-main-token.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  # Authelia JWT/session/storage-encryption secrets for the auth stack.
  "velomo-alpha/authelia-secrets.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  # Authelia file-backed user store (login + argon2id hash). Gitignored in the
  # scraper repo; shipped to the host via agenix so the auth stack can mount it.
  "velomo-alpha/authelia-users.yml.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/github-runner-token.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/scraper-app.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/doco-docker-config.json.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  # Observability (LGTM) stack: dedicated RustFS root + scoped creds and the
  # Grafana break-glass admin password. Loaded by doco-cd via the
  # observability stack's env_files entry in .doco-cd.yaml.
  "velomo-alpha/observability.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  # Slack incoming-webhook URL for Alertmanager (read via slack_api_url_file).
  # File contents are the bare URL; bind-mounted into the alertmanager container.
  "velomo-alpha/alertmanager-slack-url.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;

  # Self-hosted GitHub Actions runner registration token for the
  # Dealdodo/frontend repo. Consumed once on first registration; after
  # that the runner persists credentials. Re-generate via:
  #   gh api -X POST /repos/Dealdodo/frontend/actions/runners/registration-token --jq .token
  "velomo-alpha/frontend-runner-token.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;

  # Build-time env for the frontend CI publish job. Contains ONLY PUBLIC_*
  # values that Vite bakes into the client bundle at build time
  # (PUBLIC_POSTHOG_KEY, PUBLIC_POSTHOG_HOST). The publish workflow sources
  # this file into $GITHUB_ENV so docker/build-push-action can pass them
  # as --build-arg. Runtime secrets live in frontend-app.env, NOT here.
  "velomo-alpha/frontend-build.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;

  # Runtime env for the frontend stack (Astro app + Fider + Fider's Postgres).
  # Loaded via env_files in .doco-cd.yaml; doco-cd reads it from /run/agenix.
  # Contains:
  #   - App: DATABASE_URL (with the velomo_reader password), MEILI_HOST, MEILI_SEARCH_KEY
  #   - Fider: FIDER_BASE_URL, FIDER_DB_PASSWORD, FIDER_JWT_SECRET,
  #     FIDER_EMAIL_NOREPLY, FIDER_SMTP_{HOST,PORT,USERNAME,PASSWORD,ENABLE_STARTTLS}
  #   - Auth (Astro-side): LOGTO_ISSUER, LOGTO_CLIENT_ID, LOGTO_CLIENT_SECRET,
  #     LOGTO_M2M_CLIENT_ID, LOGTO_M2M_CLIENT_SECRET, LOGTO_MGMT_API_URL,
  #     LOGTO_DB_URL, SESSION_SECRET, GOOGLE_CLIENT_ID/SECRET, GITHUB_CLIENT_ID/SECRET,
  #     DISCORD_WEBHOOK_URL
  "velomo-alpha/frontend-app.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;

  # Runtime env for the Logto identity provider stack (logto, logto-db, oauth2-proxy).
  # Loaded via env_files in .doco-cd.yaml alongside frontend-app.env.
  # Contains: LOGTO_DB_PASSWORD, LOGTO_ENDPOINT, LOGTO_ADMIN_ENDPOINT,
  # OAUTH2_PROXY_{CLIENT_ID,CLIENT_SECRET,REDIRECT_URL,COOKIE_SECRET},
  # BACKUP_S3_{BUCKET,ENDPOINT,REGION,KEY,KEY_SECRET,URI_STYLE,VERIFY_TLS}
  # Create: cd secrets && agenix -e velomo-alpha/logto-app.env.age
  "velomo-alpha/logto-app.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;

  # Telegram bot token for the nanoclaw channel. Contents:
  #   TELEGRAM_BOT_TOKEN=...
  # Read by systemd.services.nanoclaw via EnvironmentFile.
  "n100-nanoclaw/telegram-bot-token.env.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;

  # Hevy API key (export HEVY_API_KEY=...) for the hevy MCP server. Same
  # pattern as framework-13/hevy-api-key: decrypted to a file the hevy
  # stdio server sources. Must be bind-mounted into the agent container.
  "n100-nanoclaw/hevy-api-key.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;

  # SSH private key used to push the Obsidian vault. Registered on
  # github.com/nickhartjes/obsidian as a deploy key with write access.
  "n100-nanoclaw/obsidian-deploy-key.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;

  # Claude Code OAuth token (ANTHROPIC_AUTH_TOKEN=sk-ant-oat01-...) minted by
  # `claude setup-token`. nanoclaw's default path stores this in OneCLI's cloud
  # vault; we bypass that with a `direct` gateway provider and deliver the token
  # by mount-by-reference instead, so it stays on our own infrastructure.
  # Single line, no wrapping -- an embedded newline silently breaks the token.
  # NOT named *.env: nanoclaw's mount-security blocks any mount whose resolved
  # realPath contains ".env" (a hardcoded pattern), and agenix's decrypted path
  # under /run/agenix.d/ is what gets resolved. A .env suffix here makes the
  # container mount fail regardless of the allowlist.
  "n100-nanoclaw/anthropic-token.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;

  # SSH private key giving the host clone/push access to the private
  # nickhartjes/nanoclaw mirror (upstream nanoclaw can't be private as a
  # fork, so it's mirrored into a private repo). Registered on
  # github.com/nickhartjes/nanoclaw as a deploy key with write access.
  "n100-nanoclaw/nanoclaw-deploy-key.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;
}

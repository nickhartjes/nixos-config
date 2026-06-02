let
  # Systems
  framework-13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es";
  framework-13-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es";
  velomo-alpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeRh4DdyxTgGmDYgAaYY8yT5M0MSbRz1yGPi4P/jzWS root@velomo-alpha";
  systems = [framework-13];
  velomoSystems = [velomo-alpha];
in {
  "secret1.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  # Grafana service-account token (export GRAFANA_SA_TOKEN=...) for the Velomo
  # prod observability stack's MCP. Decrypted on framework-13 to nh's home so
  # zsh can source it (see hosts/framework-13/secrets.nix + users/nh.nix).
  "framework-13/grafana-sa-token.age".publicKeys = [framework-13 framework-13-2] ++ systems;

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

  # Runtime env for the frontend container. Loaded via env_files in
  # .doco-cd.yaml; doco-cd reads it from /run/agenix. Contains DATABASE_URL
  # (with the velomo_reader password), MEILI_HOST, MEILI_SEARCH_KEY.
  "velomo-alpha/frontend-app.env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
}

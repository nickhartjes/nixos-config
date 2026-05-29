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
  };
}

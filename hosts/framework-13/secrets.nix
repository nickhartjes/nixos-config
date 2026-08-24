{lib, ...}: {
  age = {
    # Must be readable at activation time, which runs BEFORE /home is mounted
    # (only /persist and /var/log are neededForBoot -- see disko-config.nix).
    # Anything under /home/nh/.ssh is absent at that point, so agenix found no
    # identities and every secret silently failed to decrypt. The host key is
    # on /, so it is always there.
    #
    # mkForce because users/nh/secrets.nix contributes two /home/nh/.ssh paths
    # to this list. agenix skips them (test -r || continue) but warns about each
    # on every activation. The other hosts importing that module still need
    # them -- their host keys are not recipients -- so override here, not there.
    identityPaths = lib.mkForce ["/etc/ssh/ssh_host_ed25519_key"];
    secrets = {
      secret1 = {
        file = ../../secrets/secret1.age;
        path = "/home/nh/.secret1";
      };
      # Grafana MCP service-account token. Decrypted to the path nh's zsh sources
      # (users/nh.nix), so the grafana MCP in scraper's .mcp.json gets
      # GRAFANA_SA_TOKEN. owner=nh so the user's shell can read it.
      "framework-13/grafana-sa-token" = {
        file = ../../secrets/framework-13/grafana-sa-token.age;
        path = "/home/nh/.config/velomo-grafana-sa.env";
        owner = "nh";
        mode = "400";
      };
      # Hevy API key for the hevy MCP in the NH Obsidian vault's .mcp.json.
      # owner=nh so the user's shell can read it (sourced in users/nh.nix).
      "framework-13/hevy-api-key" = {
        file = ../../secrets/framework-13/hevy-api-key.age;
        path = "/home/nh/.config/hevy-mcp.env";
        owner = "nh";
        mode = "400";
      };
    };
  };
}

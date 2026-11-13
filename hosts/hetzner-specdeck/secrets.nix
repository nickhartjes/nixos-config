{...}: {
  age.secrets = {
    # SpecDeck TURN secret: the server signs credentials with it (root copies
    # it into the container's env file, specdeck.nix), coturn checks them
    # (reads it as turnserver in preStart).
    "hetzner-specdeck/specdeck-turn-secret" = {
      file = ../../secrets/hetzner-specdeck/specdeck-turn-secret.age;
      owner = "turnserver";
      mode = "400";
    };
    # Cloudflare tunnel token (remote-managed tunnel), read by
    # cloudflared-specdeck through LoadCredential.
    "hetzner-specdeck/specdeck-tunnel-token" = {
      file = ../../secrets/hetzner-specdeck/specdeck-tunnel-token.age;
      owner = "root";
      mode = "400";
    };

    # JA! Instituut (ja-instituut.nix). The registry token is read by podman
    # (root). The staging env file holds the app settings plus the Caddy
    # password hash and the Litestream key; systemd reads it as root for all
    # three services. Contents: deploy/README.md in the ja-instituut repo (2).
    "ja-instituut/ghcr-token" = {
      file = ../../secrets/ja-instituut/ghcr-token.age;
      owner = "root";
      mode = "400";
    };
    "ja-instituut/staging-env" = {
      file = ../../secrets/ja-instituut/staging-env.age;
      owner = "root";
      mode = "400";
    };
  };
}

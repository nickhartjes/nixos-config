{...}: {
  age.secrets = {
    # SpecDeck TURN secret: signalling signs credentials with it (through
    # LoadCredential), coturn checks them (reads it as turnserver in preStart).
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
  };
}

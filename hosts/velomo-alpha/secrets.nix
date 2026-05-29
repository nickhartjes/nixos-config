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
  };
}

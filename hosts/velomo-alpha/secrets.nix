{config, ...}: {
  age.secrets = {
    "velomo-alpha/komodo-db" = {
      file = ../../secrets/velomo-alpha/komodo-db.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/komodo-core-env" = {
      file = ../../secrets/velomo-alpha/komodo-core-env.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/komodo-passkey-env" = {
      file = ../../secrets/velomo-alpha/komodo-passkey-env.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/tailscale-authkey" = {
      file = ../../secrets/velomo-alpha/tailscale-authkey.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/komodo-core-config" = {
      file = ../../secrets/velomo-alpha/komodo-core-config.age;
      owner = "root";
      # World-readable so the komodo-core container process can read it.
      # Containment is the /run/agenix/ directory perms, not the file mode.
      mode = "444";
    };
  };
}

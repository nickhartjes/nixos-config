{config, ...}: {
  age.secrets = {
    # Telegram bot token, read by systemd.services.nanoclaw (Phase B) via
    # EnvironmentFile. Stays under /run/agenix; root-only is fine because
    # systemd reads EnvironmentFile as root before dropping to nh.
    "n100-nanoclaw/telegram-bot-token.env" = {
      file = ../../secrets/n100-nanoclaw/telegram-bot-token.env.age;
      owner = "root";
      mode = "400";
    };
    # Hevy API key. Decrypted to the path the hevy MCP server sources.
    # owner=nh so the user's process can read it.
    "n100-nanoclaw/hevy-api-key" = {
      file = ../../secrets/n100-nanoclaw/hevy-api-key.age;
      path = "/home/nh/.config/hevy-mcp.env";
      owner = "nh";
      mode = "400";
    };
    # Deploy key for pushing the Obsidian vault.
    "n100-nanoclaw/obsidian-deploy-key" = {
      file = ../../secrets/n100-nanoclaw/obsidian-deploy-key.age;
      path = "/home/nh/.ssh/id_obsidian";
      owner = "nh";
      mode = "400";
    };
    # Deploy key for cloning/pushing the private nickhartjes/nanoclaw
    # mirror of upstream nanoclaw (forks can't be private, so it's
    # mirrored into a separate private repo).
    # Claude OAuth token, consumed by the agent container via mount-by-reference
    # (nanoclaw refuses credential VALUES in container env; absolute paths are
    # the sanctioned channel). owner=nh so the host process can mount it.
    "n100-nanoclaw/anthropic-token" = {
      file = ../../secrets/n100-nanoclaw/anthropic-token.age;
      path = "/home/nh/.config/nanoclaw-anthropic-token";
      owner = "nh";
      mode = "400";
    };
    "n100-nanoclaw/nanoclaw-deploy-key" = {
      file = ../../secrets/n100-nanoclaw/nanoclaw-deploy-key.age;
      path = "/home/nh/.ssh/id_nanoclaw";
      owner = "nh";
      mode = "400";
    };
  };
}

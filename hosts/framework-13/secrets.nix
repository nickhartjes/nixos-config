{
  age = {
    identityPaths = ["/home/nh/.ssh/id_framework-13_2025-06-07"];
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
    };
  };
}

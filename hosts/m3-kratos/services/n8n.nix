{
  services.n8n = {
    enable = true;
    openFirewall = true;
  };
  systemd.services.n8n = {
    environment = {
      N8N_SECURE_COOKIE = "false";
    };
  };
}

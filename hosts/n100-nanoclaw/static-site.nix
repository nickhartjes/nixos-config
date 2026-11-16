{
  config,
  pkgs,
  lib,
  ...
}: let
  # The tunnel only exists once its token secret has been created
  # (`agenix -e n100-nanoclaw/site-tunnel.env.age`, contents: TUNNEL_TOKEN=<token>).
  # Until then this module serves the site on localhost only.
  tunnelSecret = ../../secrets/n100-nanoclaw/site-tunnel.env.age;
  tunnelReady = builtins.pathExists tunnelSecret;
in {
  # ---- A static site, published through a Cloudflare Tunnel.
  # Files are pushed by rsync (as nh) into /var/www/site; nginx serves them on
  # localhost only. cloudflared dials out to Cloudflare, so there is no inbound
  # port and the home IP stays hidden. The tunnel is remotely managed: which
  # public hostname maps to http://127.0.0.1:8787 is set in the Cloudflare
  # dashboard, not here, and the token lives in agenix.

  systemd.tmpfiles.rules = [
    "d /var/www 0755 root root - -"
    "d /var/www/site 0755 nh users - -"
  ];

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    # Only ever reached through the tunnel; never on the LAN or tailnet.
    defaultListen = [
      {
        addr = "127.0.0.1";
        port = 8787;
      }
    ];
    virtualHosts."static-site" = {
      default = true;
      root = "/var/www/site";
      extraConfig = ''
        # Astro builds /tool as tool.html (trailingSlash: never, format: file).
        location / {
          try_files $uri $uri.html $uri/ =404;
        }
        location /_astro/ {
          add_header Cache-Control "public, max-age=31536000, immutable";
        }
        add_header X-Content-Type-Options nosniff always;
        add_header Referrer-Policy strict-origin-when-cross-origin always;
      '';
    };
  };

  age.secrets = lib.mkIf tunnelReady {
    "n100-nanoclaw/site-tunnel.env" = {
      file = tunnelSecret;
      owner = "root";
      mode = "400";
    };
  };

  systemd.services.site-tunnel = lib.mkIf tunnelReady {
    description = "Cloudflare Tunnel for the static site";
    after = ["network-online.target" "nginx.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      # TUNNEL_TOKEN comes from the env file; cloudflared reads it for `tunnel run`.
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
      EnvironmentFile = config.age.secrets."n100-nanoclaw/site-tunnel.env".path;
      DynamicUser = true;
      Restart = "always";
      RestartSec = "10s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      CapabilityBoundingSet = "";
    };
  };
}

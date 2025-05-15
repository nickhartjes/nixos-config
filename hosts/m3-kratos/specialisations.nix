{
  config,
  lib,
  pkgs,
  ...
}: {
  specialisation = {
    "HTTPD".configuration = {
      system.nixos.tags = ["HTTPD"];
      services.httpd.enable = true;
      services.httpd.virtualHosts."foo.example.com" = {
        documentRoot = "/var/www/foo";
        extraConfig = ''
          <Directory /var/www/foo>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride None
            Require all granted
          </Directory>
        '';
      };
    };
    "NGINX".configuration = {
      system.nixos.tags = ["NGINX"];
      services.httpd.enable = false;
      services.nginx.enable = true;
      services.nginx.config = ''
        http {
          server {
            listen 80;
            server_name bar.example.com;

            root /var/www/bar;

            location / {
              index index.html;
            }
          }
        }
      '';
    };
    "NVIDIA".configuration = {
      boot.kernelParams = [
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        "nvidia-drm.modeset=1"
      ];
      system.nixos.tags = ["NVIDIA"];
      services.xserver.videoDrivers = ["nvidia"];
      hardware = {
        nvidia = {
          open = false;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          modesetting.enable = true;
          powerManagement.enable = true;
        };
        graphics = {
          enable = true;
          enable32Bit = true;
        };
      };
      environment.sessionVariables = {
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";
        QT_QPA_PLATFORM = "wayland";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_SESSION_TYPE = "wayland";
      };
    };
  };
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "switch-spec" ''
      if [ $# -ne 1 ]; then
        echo "Usage: switch-spec <specialisation>"
        exit 1
      fi

      sudo /nix/var/nix/profiles/system/specialisation/$1/bin/switch-to-configuration switch
    '')
  ];
  environment.sessionVariables = lib.mkIf (config.specialisation != {}) {
    SPECIALISATION = "NONE";
  };
}

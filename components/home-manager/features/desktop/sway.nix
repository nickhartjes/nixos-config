{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home-manager.features.desktop.sway = {
    enable = lib.mkEnableOption "Sway user configuration";
  };

  config = lib.mkIf config.home-manager.features.desktop.sway.enable {
    wayland.windowManager.sway = {
      enable = true;
      config = rec {
        modifier = "Mod4"; # Use Super key
        terminal = "${pkgs.foot}/bin/foot";
        menu = "${pkgs.wofi}/bin/wofi --show drun";

        startup = [
          # Launch applications on startup
          {command = "${pkgs.swaynotificationcenter}/bin/swaync";}
          {command = "${pkgs.networkmanagerapplet}/bin/nm-applet";}
        ];

        keybindings = lib.mkOptionDefault {
          # Custom keybindings
          "${modifier}+Return" = "exec ${terminal}";
          "${modifier}+d" = "exec ${menu}";
          "${modifier}+Shift+q" = "kill";
          "${modifier}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";

          # Screenshot bindings
          "Print" = "exec ${pkgs.grim}/bin/grim";
          "Shift+Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\"";

          # Audio controls
          "XF86AudioRaiseVolume" = "exec ${pkgs.pavucontrol}/bin/pavucontrol";
          "XF86AudioLowerVolume" = "exec ${pkgs.pavucontrol}/bin/pavucontrol";
          "XF86AudioMute" = "exec ${pkgs.pavucontrol}/bin/pavucontrol";
        };

        input = {
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
          };
        };

        output = {
          "*" = {
            bg = "~/.config/wallpaper fill";
          };
        };

        bars = [
          {
            position = "top";
            command = "${pkgs.waybar}/bin/waybar";
          }
        ];
      };
    };

    # Waybar configuration
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = ["sway/workspaces" "sway/mode"];
          modules-center = ["sway/window"];
          modules-right = ["pulseaudio" "network" "battery" "clock"];

          "sway/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
          };

          clock = {
            format = "{:%Y-%m-%d %H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-icons = ["" "" "" "" ""];
          };

          network = {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
            format-disconnected = "Disconnected ⚠";
          };

          pulseaudio = {
            format = "{volume}% {icon}";
            format-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["" "" ""];
            };
            on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          };
        };
      };
    };

    # Additional sway-related packages
    home.packages = with pkgs; [
      # Core sway tools
      swaylock
      swayidle
      swaybg
      swaynotificationcenter

      # Wayland utilities
      wl-clipboard
      wf-recorder
      grim
      slurp

      # Application launcher
      wofi

      # Terminal
      foot

      # Image viewer
      imv

      # File manager
      thunar
    ];

    # Swaylock configuration
    programs.swaylock = {
      enable = true;
      settings = {
        color = "808080";
        font-size = 24;
        indicator-idle-visible = false;
        indicator-radius = 100;
        line-color = "ffffff";
        show-failed-attempts = true;
      };
    };

    # Swayidle configuration
    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.swaylock}/bin/swaylock -fF";
        }
        {
          timeout = 600;
          command = "${pkgs.sway}/bin/swaymsg \"output * dpms off\"";
          resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\"";
        }
      ];
    };
  };
}

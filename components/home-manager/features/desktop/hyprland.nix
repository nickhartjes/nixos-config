{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.features.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland user configuration";
  };

  config = lib.mkIf config.components.features.desktop.hyprland.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        # Monitor configuration
        monitor = ",preferred,auto,auto";

        # Input configuration
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "";
          kb_rules = "";

          follow_mouse = 1;

          touchpad = {
            natural_scroll = "yes";
            tap-to-click = "yes";
          };

          sensitivity = 0;
        };

        # General settings
        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
          "col.inactive_border" = "rgba(595959aa)";

          layout = "dwindle";

          allow_tearing = false;
        };

        # Decoration settings
        decoration = {
          rounding = 10;

          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };

          drop_shadow = "yes";
          shadow_range = 4;
          shadow_render_power = 3;
          "col.shadow" = "rgba(1a1a1aee)";
        };

        # Animation settings
        animations = {
          enabled = "yes";

          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };

        # Layout settings
        dwindle = {
          pseudotile = "yes";
          preserve_split = "yes";
        };

        master = {
          new_is_master = true;
        };

        # Gestures
        gestures = {
          workspace_swipe = false;
        };

        # Misc settings
        misc = {
          force_default_wallpaper = -1;
        };

        # Window rules
        windowrulev2 = [
          "suppressevent maximize, class:.*"
          "float,class:^(pavucontrol)$"
          "float,class:^(nm-applet)$"
        ];

        # Key bindings
        "$mod" = "SUPER";

        bind = [
          # Application bindings
          "$mod, Return, exec, ${pkgs.foot}/bin/foot"
          "$mod, Q, killactive,"
          "$mod, M, exit,"
          "$mod, E, exec, ${pkgs.xfce.thunar}/bin/thunar"
          "$mod, V, togglefloating,"
          "$mod, D, exec, ${pkgs.wofi}/bin/wofi --show drun"
          "$mod, P, pseudo,"
          "$mod, J, togglesplit,"

          # Move focus
          "$mod, left, movefocus, l"
          "$mod, right, movefocus, r"
          "$mod, up, movefocus, u"
          "$mod, down, movefocus, d"

          # Switch workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod, 6, workspace, 6"
          "$mod, 7, workspace, 7"
          "$mod, 8, workspace, 8"
          "$mod, 9, workspace, 9"
          "$mod, 0, workspace, 10"

          # Move active window to workspace
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"
          "$mod SHIFT, 6, movetoworkspace, 6"
          "$mod SHIFT, 7, movetoworkspace, 7"
          "$mod SHIFT, 8, movetoworkspace, 8"
          "$mod SHIFT, 9, movetoworkspace, 9"
          "$mod SHIFT, 0, movetoworkspace, 10"

          # Special workspace
          "$mod, S, togglespecialworkspace, magic"
          "$mod SHIFT, S, movetoworkspace, special:magic"

          # Scroll through workspaces
          "$mod, mouse_down, workspace, e+1"
          "$mod, mouse_up, workspace, e-1"

          # Screenshot bindings
          ", Print, exec, ${pkgs.grim}/bin/grim"
          "SHIFT, Print, exec, ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\""
        ];

        # Mouse bindings
        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        # Execute on startup
        exec-once = [
          "${pkgs.waybar}/bin/waybar"
          "${pkgs.mako}/bin/mako"
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "${pkgs.hyprpaper}/bin/hyprpaper"
        ];
      };
    };

    # Waybar configuration for Hyprland
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = ["hyprland/workspaces" "hyprland/mode"];
          modules-center = ["hyprland/window"];
          modules-right = ["pulseaudio" "network" "battery" "clock"];

          "hyprland/workspaces" = {
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

    # Hyprpaper configuration for wallpapers
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;

        preload = [
          "~/.config/wallpaper"
        ];

        wallpaper = [
          ",~/.config/wallpaper"
        ];
      };
    };

    # Additional Hyprland-related packages (minimal set - others should be in system config)
    home.packages = with pkgs; [
      # User-specific Hyprland tools only
      hyprpicker
      wl-clipboard

      # Note: Other packages like foot, kitty, wofi, etc. should be
      # installed via their respective component modules for better modularity
    ];

    # Mako notification daemon configuration
    services.mako = {
      enable = true;
      backgroundColor = "#2e3440";
      borderColor = "#88c0d0";
      borderRadius = 5;
      borderSize = 2;
      defaultTimeout = 5000;
      font = "Noto Sans 10";
      textColor = "#eceff4";
    };
  };
}

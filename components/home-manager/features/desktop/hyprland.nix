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
        # Variables
        "$mainMod" = "SUPER";
        "$terminal" = "${pkgs.ghostty}/bin/ghostty";
        "$browser" = "chromium"; # Use desktop entry name instead of direct path
        # "$fileManager" = "${pkgs.pcmanfm}/bin/pcmanfm";
        "$menu" = "${pkgs.wofi}/bin/wofi --show drun";

        # Monitor configuration
        monitor = [
          ",preferred,auto,1.5"
          "desc:Samsung Electric Company Odyssey G95SC H1AK500000,5120x1440,auto,1"
        ];

        # Input configuration
        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "caps:escape";
          kb_rules = "";

          follow_mouse = 1;

          touchpad = {
            natural_scroll = "yes";
            tap-to-click = true;
            drag_lock = true;
          };

          sensitivity = 0.5;
        };

        # General settings
        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 3;
          "col.active_border" = "0x661e81b0";
          "col.inactive_border" = "0x66333333";
        };

        # Decoration settings
        decoration = {
          rounding = 3;
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
          };
        };

        # Animation settings
        animations = {
          enabled = 1;
          animation = [
            "windows,1,7,default"
            "border,1,10,default"
            "fade,1,10,default"
            "workspaces,1,6,default"
          ];
        };

        # Layout settings
        dwindle = {
          pseudotile = 0;
        };

        # Gestures
        gestures = {
          workspace_swipe = "yes";
        };

        # Window rules
        windowrulev2 = [
          "opacity 0.8 0.8,class:^(ghostty)$"
          "animation popin,class:^(alacritty)$,title:^(update-sys)$"
          "animation popin,class:^(thunar)$"
          "opacity 0.8 0.8,class:^(thunar)$"
          "opacity 0.8 0.8,class:^(VSCodium)$"
          "animation popin,class:^(chromium)$"
          "move cursor -3% -105%,class:^(wofi)$"
        ];

        windowrule = [
          "animation popin, class:ghostty"
          "noblur, class:firefox"
          "bordercolor rgb(FF0000) rgb(880808), fullscreen:1"
          "bordercolor rgb(00FF00), fullscreenstate:* 1"
          "stayfocused, class:(pinentry-)(.*)"
          "workspace special:slack, class:slack"
          "workspace special:terminal, class:ghostty"
          "workspace special:music, class:spotify"
        ];

        # Mouse bindings
        bindm = [
          "$mainMod,mouse:272,movewindow"
          "$mainMod,mouse:273,resizewindow"
        ];

        # Key bindings
        bind = [
          # Application bindings
          "$mainMod,RETURN,exec,$terminal"
          "$mainMod,B,exec,$browser"
          "$mainMod,F,fullscreen"
          "$mainMod,Q,killactive"
          "$mainMod ALT,L,exec,${pkgs.hyprlock}/bin/hyprlock"
          "$mainMod SHIFT,Q,exec,${pkgs.wlogout}/bin/wlogout --protocol layer-shell"
          "$mainMod SHIFT,M,exit"
          "$mainMod,E,exec,$fileManager"
          "$mainMod,V,togglefloating"
          "$mainMod,P,exec,$menu"
          "$mainMod,S,exec,${pkgs.grim}/bin/grim -t jpeg -q 10 -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.swappy}/bin/swappy -f -"

          # Focus bindings (vim motions: h=left, j=down, k=up, l=right)
          "$mainMod,h,movefocus,l"
          "$mainMod,j,movefocus,d"
          "$mainMod,k,movefocus,u"
          "$mainMod,l,movefocus,r"

          # Window movement bindings (vim motions: h=left, j=down, k=up, l=right)
          "$mainMod SHIFT,h,movewindow,l"
          "$mainMod SHIFT,j,movewindow,d"
          "$mainMod SHIFT,k,movewindow,u"
          "$mainMod SHIFT,l,movewindow,r"

          # Workspace bindings
          "$mainMod,1,workspace,1"
          "$mainMod,2,workspace,2"
          "$mainMod,3,workspace,3"
          "$mainMod,4,workspace,4"
          "$mainMod,5,workspace,5"
          "$mainMod,6,workspace,6"
          "$mainMod,7,workspace,7"
          "$mainMod,8,workspace,8"
          "$mainMod,9,workspace,9"
          "$mainMod,0,workspace,10"

          # Move window to workspace
          "$mainMod SHIFT,1,movetoworkspace,1"
          "$mainMod SHIFT,2,movetoworkspace,2"
          "$mainMod SHIFT,3,movetoworkspace,3"
          "$mainMod SHIFT,4,movetoworkspace,4"
          "$mainMod SHIFT,5,movetoworkspace,5"
          "$mainMod SHIFT,6,movetoworkspace,6"
          "$mainMod SHIFT,7,movetoworkspace,7"
          "$mainMod SHIFT,8,movetoworkspace,8"
          "$mainMod SHIFT,9,movetoworkspace,9"
          "$mainMod SHIFT,0,movetoworkspace,10"

          # Mouse wheel workspace switching
          "$mainMod,mouse_down,workspace,e+1"
          "$mainMod,mouse_up,workspace,e-1"

          # Special workspaces
          "ALT,S,togglespecialworkspace,slack"
          "ALT,T,togglespecialworkspace,terminal"
          "ALT,M,togglespecialworkspace,music"

          # Window resize submap
          "$mainMod,R,submap,resize"

          # Media key bindings
          # ",XF86AudioPlay,exec,~/.config/hypr/scripts/brightness.sh --play-pause"
          # ",XF86AudioPause,exec,~/.config/hypr/scripts/brightness.sh --play-pause"
          # ",XF86AudioNext,exec,~/.config/hypr/scripts/brightness.sh --next"
          # ",XF86AudioPrev,exec,~/.config/hypr/scripts/brightness.sh --previous"
        ];

        # Media controls
        binde = [
          # ",XF86AudioRaiseVolume,exec,~/.config/hypr/scripts/brightness.sh --volume-up"
          # ",XF86AudioLowerVolume,exec,~/.config/hypr/scripts/brightness.sh --volume-down"
          # ",XF86AudioMute,exec,~/.config/hypr/scripts/brightness.sh --mute-toggle"
          # ",XF86MonBrightnessUp,exec,~/.config/hypr/scripts/brightness.sh --inc"
          # ",XF86MonBrightnessDown,exec,~/.config/hypr/scripts/brightness.sh --dec"
        ];

        # Laptop lid switch
        bindl = [
          ",switch:on:Lid Switch,exec,${pkgs.hyprland}/bin/hyprctl keyword monitor \"eDP-1, disable\""
          ",switch:off:Lid Switch,exec,${pkgs.hyprland}/bin/hyprctl keyword monitor \"eDP-1, 1920x1080, 0x0, 1\""
        ];

        # Execute on startup
        exec-once = [
          "${pkgs.hyprpanel}/bin/hyprpanel"
          "${pkgs.kanshi}/bin/kanshi"
          "${pkgs.hypridle}/bin/hypridle"
          "[workspace special:slack silent] ${pkgs.slack}/bin/slack"
          "[workspace special:terminal silent] ${pkgs.ghostty}/bin/ghostty"
          "[workspace special:music silent] ${pkgs.spotify}/bin/spotify"
        ];

        # Plugin configuration
        plugin = {
          hy3 = {
            tabs = {
              border_width = 1;
              "col.active" = "rgba(33ccff20)";
              "col.border.active" = "rgba(33ccffee)";
              "col.text.active" = "rgba(ffffffff)";
              "col.inactive" = "rgba(30303020)";
              "col.border.inactive" = "rgba(595959aa)";
            };
            autotile = {
              enable = true;
              trigger_width = 800;
              trigger_height = 500;
            };
          };
        };
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
          "~/.config/wallpaper"
        ];
      };
    };

    # Additional Hyprland-related packages
    home.packages = with pkgs; [
      # Core applications (note: chromium is installed via browser component)
      ghostty
      # pcmanfm
      wofi

      # System tools
      hyprlock
      wlogout
      hyprpanel
      kanshi
      hypridle

      yazi

      # Screenshot and utilities
      grim
      slurp
      swappy

      # User-specific Hyprland tools
      hyprpicker
      wl-clipboard
    ];

    # Mako notification daemon configuration
    services.mako = {
      enable = true;
      settings = {
        backgroundColor = "#2e3440";
        borderColor = "#88c0d0";
        borderRadius = 5;
        borderSize = 2;
        defaultTimeout = 5000;
        font = "Noto Sans 10";
        textColor = "#eceff4";
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.components.features.desktop.mangowc;
  noctaliaBin = "${inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia-shell";
  noctalia = cmd: "${noctaliaBin} ipc call ${cmd}";
  dmsBin = "${inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/dms";
  dms = cmd: "${dmsBin} ipc call ${cmd}";
  hasShell = cfg.enableNoctalia || cfg.enableDMS;
in {
  imports = [
    inputs.mango.hmModules.mango
  ];

  options.components.features.desktop.mangowc = {
    enable = lib.mkEnableOption "MangoWC user configuration";
    enableNoctalia = lib.mkEnableOption "Noctalia shell integration with MangoWC";
    enableDMS = lib.mkEnableOption "Dank Material Shell integration with MangoWC";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.enableNoctalia && cfg.enableDMS);
        message = "Cannot enable both Noctalia and Dank Material Shell for MangoWC. Choose one.";
      }
    ];

    wayland.windowManager.mango = {
      enable = true;

      settings = let
        keybindings = import ./mangowc-keybindings.nix {
          inherit pkgs noctalia dms hasShell lib;
          enableNoctalia = cfg.enableNoctalia;
          enableDMS = cfg.enableDMS;
        };
      in
        {
          # Input configuration
          xkb_rules_layout = "us";
          xkb_rules_options = "caps:escape";
          tap_to_click = 1;
          trackpad_natural_scrolling = 1;
          trackpad_disable_while_typing = 1;

          # Environment variables
          env = [
            "NIXOS_OZONE_WL,1"
            "MOZ_ENABLE_WAYLAND,1"
            "QT_QPA_PLATFORM,wayland"
            "SDL_VIDEODRIVER,wayland"
            "_JAVA_AWT_WM_NONREPARENTING,1"
            "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
            "QT_AUTO_SCREEN_SCALE_FACTOR,1"
            "XDG_CURRENT_DESKTOP,mango"
          ];

          # Autostart
          exec-once =
            [
              "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
              "${pkgs.swaybg}/bin/swaybg -i ~/.config/wallpaper -m fill"
              "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
              "${pkgs.networkmanagerapplet}/bin/nm-applet"
            ]
            ++ lib.optionals cfg.enableNoctalia [
              noctaliaBin
            ]
            ++ lib.optionals cfg.enableDMS [
              "${dmsBin} run --session"
            ]
            ++ lib.optionals (!hasShell) [
              "${pkgs.swaynotificationcenter}/bin/swaync"
            ];

          # Output configuration
          monitorrule = [
            "name:DP-.*,width:5120,height:1440,refresh:120,x:0,y:0,scale:1"
            "name:eDP-1,scale:1.5,x:5120,y:0"
          ];

          # Blur & shadows
          blur = 1;
          blur_params_radius = 5;
          blur_params_num_passes = 2;
          blur_params_brightness = 0.9;
          shadows = 1;
          shadow_only_floating = 1;
          shadows_size = 10;
          shadows_blur = 15;

          # Border & corner radius (Catppuccin Mocha colors)
          border_radius = 8;
          borderpx = 3;
          focuscolor = "0x89b4faff";
          bordercolor = "0x313244ff";
          scratchpadcolor = "0x94e2d5ff";

          # Gaps
          gappih = 6;
          gappiv = 6;
          gappoh = 10;
          gappov = 10;

          # Window opacity
          unfocused_opacity = 0.92;

          # Animations
          animations = 1;
          animation_type_open = "zoom";
          animation_type_close = "fade";
          animation_duration_open = 300;
          animation_duration_close = 200;
          animation_duration_move = 300;

          # Cursor
          cursor_size = 24;

          # Scroller tuning
          scroller_default_proportion = 0.5;
          scroller_focus_center = 0;
          scroller_prefer_overspread = 1;
          scroller_proportion_preset = "0.33,0.5,0.67,0.8,1.0";

          # Layouts - set all tags to scroller
          tagrule = [
            "id:1,layout_name:scroller"
            "id:2,layout_name:scroller"
            "id:3,layout_name:scroller"
            "id:4,layout_name:scroller"
            "id:5,layout_name:scroller"
            "id:6,layout_name:scroller"
            "id:7,layout_name:scroller"
            "id:8,layout_name:scroller"
            "id:9,layout_name:scroller"
          ];
        }
        // keybindings;

      # Keep autostart_sh non-empty so the mango hm-module generates the file
      # with systemd/dbus activation. Programs are launched via exec-once in config.conf.
      autostart_sh = ''
        # Programs are started via exec-once in config.conf
      '';
    };

    # Supporting packages
    home.packages = with pkgs;
      [
        adw-gtk3
        grim
        nwg-look
        slurp
        swaybg
        wl-clipboard
        wdisplays
        xwayland-satellite
      ]
      ++ lib.optionals (!hasShell) [
        wofi
        swaynotificationcenter
      ];
  };
}

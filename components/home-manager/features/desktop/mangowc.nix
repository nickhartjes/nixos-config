{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.components.features.desktop.mangowc;
  noctaliaBin = "${inputs.noctalia.packages.${pkgs.system}.default}/bin/noctalia-shell";
  noctalia = cmd: "${noctaliaBin} ipc call ${cmd}";
  dmsBin = "${inputs.dms.packages.${pkgs.system}.default}/bin/dms";
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
          inherit pkgs noctalia hasShell lib;
          enableNoctalia = cfg.enableNoctalia;
        };
        noctaliaExecOnce = lib.optionalString cfg.enableNoctalia ''
          exec-once=sh -c 'rm -f ~/.config/noctalia/settings.json && cp ~/.config/noctalia/settings-mango.json ~/.config/noctalia/settings.json && exec ${noctaliaBin}'
        '';
        dmsExecOnce = lib.optionalString cfg.enableDMS ''
          exec-once=${dmsBin} run --session
        '';
      in ''
        # Input configuration
        xkb_rules_layout=us
        xkb_rules_options=caps:escape
        tap_to_click=1
        trackpad_natural_scrolling=1
        disable_while_typing=1

        # Environment variables
        env=NIXOS_OZONE_WL,1
        env=MOZ_ENABLE_WAYLAND,1
        env=QT_QPA_PLATFORM,wayland
        env=SDL_VIDEODRIVER,wayland
        env=_JAVA_AWT_WM_NONREPARENTING,1
        env=QT_WAYLAND_DISABLE_WINDOWDECORATION,1
        env=QT_AUTO_SCREEN_SCALE_FACTOR,1
        env=XDG_CURRENT_DESKTOP,mango

        # Autostart
        exec-once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        exec-once=${pkgs.swaybg}/bin/swaybg -i ~/.config/wallpaper -m fill
        exec-once=${pkgs.xwayland-satellite}/bin/xwayland-satellite
        exec-once=${pkgs.networkmanagerapplet}/bin/nm-applet
        ${noctaliaExecOnce}
        ${dmsExecOnce}
        ${lib.optionalString (!hasShell) ''
          exec-once=${pkgs.swaynotificationcenter}/bin/swaync
        ''}

        # Output configuration
        monitorrule=name:eDP-1,scale:1.5

        # Blur & shadows
        blur=1
        blur_params_radius=5
        blur_params_num_passes=2
        blur_params_brightness=0.9
        shadows=1
        shadow_only_floating=1
        shadows_size=10
        shadows_blur=15

        # Border & corner radius (Catppuccin Mocha colors)
        border_radius=8
        borderpx=3
        focuscolor=0x89b4faff
        bordercolor=0x313244ff
        scratchpadcolor=0x94e2d5ff

        # Gaps
        gappih=6
        gappiv=6
        gappoh=10
        gappov=10

        # Window opacity
        unfocused_opacity=0.92

        # Animations
        animations=1
        animation_type_open=zoom
        animation_type_close=fade
        animation_duration_open=300
        animation_duration_close=200
        animation_duration_move=300

        # Cursor
        cursor_size=24

        # Scroller tuning
        scroller_default_proportion=0.5
        scroller_focus_center=0
        scroller_prefer_overspread=1
        scroller_proportion_preset=0.33,0.5,0.67,0.8,1.0

        # Layouts - set all tags to scroller
        tagrule=id:1,layout_name:scroller
        tagrule=id:2,layout_name:scroller
        tagrule=id:3,layout_name:scroller
        tagrule=id:4,layout_name:scroller
        tagrule=id:5,layout_name:scroller
        tagrule=id:6,layout_name:scroller
        tagrule=id:7,layout_name:scroller
        tagrule=id:8,layout_name:scroller
        tagrule=id:9,layout_name:scroller

        ${keybindings}
      '';

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

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
        noctaliaBindings = lib.optionalString cfg.enableNoctalia ''
          # Noctalia keybindings
          bind=SUPER,SPACE,spawn,${noctalia "launcher toggle"}
          bind=SUPER,P,spawn,${noctalia "sessionMenu toggle"}
          bind=SUPER,O,spawn,${noctalia "overview toggle"}
          bind=CTRL+SUPER,L,spawn,${noctalia "lockScreen lock"}
          bind=SUPER,V,spawn,${noctalia "launcher clipboard"}
          bind=SUPER,E,spawn,${noctalia "launcher emoji"}
          bind=SUPER,TAB,spawn,${noctalia "launcher windows"}
          bind=SUPER,N,spawn,${noctalia "controlCenter toggle"}
          bind=SUPER,C,spawn,${noctalia "calendar toggle"}
          bind=SUPER+SHIFT,ESCAPE,spawn,${noctalia "systemMonitor toggle"}
          bind=SUPER+SHIFT,D,spawn,${noctalia "launcher command"}
          bindl=NONE,XF86AudioRaiseVolume,spawn,${noctalia "volume increase"}
          bindl=NONE,XF86AudioLowerVolume,spawn,${noctalia "volume decrease"}
          bindl=NONE,XF86AudioMute,spawn,${noctalia "volume muteOutput"}
          bindl=NONE,XF86MonBrightnessUp,spawn,${noctalia "brightness increase"}
          bindl=NONE,XF86MonBrightnessDown,spawn,${noctalia "brightness decrease"}
        '';
        noctaliaExecOnce = lib.optionalString cfg.enableNoctalia ''
          exec-once=${noctaliaBin}
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

        # Autostart
        exec-once=${pkgs.xwayland-satellite}/bin/xwayland-satellite
        exec-once=${pkgs.networkmanagerapplet}/bin/nm-applet
        ${noctaliaExecOnce}
        ${dmsExecOnce}
        ${lib.optionalString (!hasShell) ''
          exec-once=${pkgs.swaynotificationcenter}/bin/swaync
        ''}

        # Application launchers
        bind=SUPER,RETURN,spawn,${pkgs.ghostty}/bin/ghostty
        ${lib.optionalString (!hasShell) ''
          bind=SUPER,D,spawn,${pkgs.wofi}/bin/wofi --show drun
        ''}
        bind=SUPER,B,spawn,chromium

        # Window management
        bind=SUPER,Q,killclient
        bind=SUPER+SHIFT,E,quit

        # Focus movement
        bind=SUPER,H,focusdir,left
        bind=SUPER,J,focusdir,down
        bind=SUPER,K,focusdir,up
        bind=SUPER,L,focusdir,right
        bind=SUPER,LEFT,focusdir,left
        bind=SUPER,DOWN,focusdir,down
        bind=SUPER,UP,focusdir,up
        bind=SUPER,RIGHT,focusdir,right

        # Move windows
        bind=SUPER+SHIFT,H,movewin,left
        bind=SUPER+SHIFT,J,movewin,down
        bind=SUPER+SHIFT,K,movewin,up
        bind=SUPER+SHIFT,L,movewin,right

        # Tags (workspaces)
        bind=SUPER,1,view,1,0
        bind=SUPER,2,view,2,0
        bind=SUPER,3,view,3,0
        bind=SUPER,4,view,4,0
        bind=SUPER,5,view,5,0
        bind=SUPER,6,view,6,0
        bind=SUPER,7,view,7,0
        bind=SUPER,8,view,8,0
        bind=SUPER,9,view,9,0

        # Move window to tag
        bind=SUPER+SHIFT,1,tag,1,0
        bind=SUPER+SHIFT,2,tag,2,0
        bind=SUPER+SHIFT,3,tag,3,0
        bind=SUPER+SHIFT,4,tag,4,0
        bind=SUPER+SHIFT,5,tag,5,0
        bind=SUPER+SHIFT,6,tag,6,0
        bind=SUPER+SHIFT,7,tag,7,0
        bind=SUPER+SHIFT,8,tag,8,0
        bind=SUPER+SHIFT,9,tag,9,0

        # Fullscreen
        bind=SUPER,F,togglefullscreen
        bind=SUPER,M,togglemaximizescreen

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

        # Ghostty scratchpad
        windowrule=isnamedscratchpad:1,width:1280,height:800,appid:ghostty-scratchpad
        bind=SUPER,S,toggle_named_scratchpad,ghostty-scratchpad,none,${pkgs.ghostty}/bin/ghostty --class=ghostty-scratchpad

        # Screenshots
        bind=NONE,PRINT,spawn,${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" ~/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png

        ${noctaliaBindings}
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
        grim
        slurp
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

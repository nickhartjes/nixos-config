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
  # Same package the caelestia HM module installs. The wrapper passes the
  # config path, so `caelestia-shell ipc call` reaches the running instance.
  caelestiaBin = "${config.programs.caelestia.package}/bin/caelestia-shell";
  caelestia = cmd: "${caelestiaBin} ipc call ${cmd}";
  hasShell = cfg.enableNoctalia || cfg.enableDMS || cfg.enableCaelestia;
  keybindings = import ./mangowc-keybindings.nix {
    inherit pkgs noctalia dms dmsBin caelestia hasShell lib;
    enableNoctalia = cfg.enableNoctalia;
    enableDMS = cfg.enableDMS;
    enableCaelestia = cfg.enableCaelestia;
  };
  bindTypes = ["bind" "bindl"];
  swaylock = "${pkgs.swaylock}/bin/swaylock -f";
  # swayidle runs this through sh -c. If the shell isn't running the IPC call
  # fails and swaylock locks instead. Not used with DMS, which locks on idle
  # and before suspend itself.
  lockCmd =
    if cfg.enableCaelestia
    then "${caelestia "lock lock"} || ${swaylock}"
    else if cfg.enableNoctalia
    then "${noctalia "lockScreen lock"} || ${swaylock}"
    else swaylock;
  # Wrapped in a script: mango rejects config lines over 255 bytes.
  idleLock = pkgs.writeShellScript "mango-idle-lock" ''
    exec ${pkgs.swayidle}/bin/swayidle -w \
      timeout 600 '${lockCmd}' \
      before-sleep '${lockCmd}'
  '';
in {
  imports = [
    inputs.mango.hmModules.mango
  ];

  options.components.features.desktop.mangowc = {
    enable = lib.mkEnableOption "MangoWC user configuration";
    enableNoctalia = lib.mkEnableOption "Noctalia shell integration with MangoWC";
    enableDMS = lib.mkEnableOption "Dank Material Shell integration with MangoWC";
    enableCaelestia = lib.mkEnableOption "Caelestia shell integration with MangoWC";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.count lib.id [cfg.enableNoctalia cfg.enableDMS cfg.enableCaelestia] <= 1;
        message = "Enable at most one of Noctalia, Dank Material Shell and Caelestia for MangoWC.";
      }
      {
        assertion = cfg.enableCaelestia -> config.components.features.desktop.caelestia.enable;
        message = "components.features.desktop.mangowc.enableCaelestia needs components.features.desktop.caelestia.enable.";
      }
    ];

    # Bound to mango's session target, not graphical-session.target, so DMS
    # doesn't also start under niri or another session on the same host.
    programs.dank-material-shell.systemd = lib.mkIf cfg.enableDMS {
      enable = true;
      target = "mango-session.target";
    };

    wayland.windowManager.mango = {
      enable = true;

      # DMS's service needs this to write ~/.config/mango/dms/colors.conf
      # and reload mango. mkOptionDefault keeps the module's default list.
      systemd.variables = lib.mkOptionDefault ["MANGO_INSTANCE_SIGNATURE"];

      settings =
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
          exec_once =
            [
              "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
              "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
            ]
            # Lock after 10 min idle and before every suspend (lid, logind idle).
            # DMS does this itself (acLockTimeout/batteryLockTimeout and
            # lockBeforeSuspend in ~/.config/dms/settings.json), so only the
            # other shells need swayidle.
            ++ lib.optionals (!cfg.enableDMS) [
              "${idleLock}"
            ]
            ++ lib.optionals cfg.enableNoctalia [
              noctaliaBin
            ]
            # DMS runs as a systemd service (below) so it restarts if it dies.
            ++ lib.optionals cfg.enableCaelestia [
              caelestiaBin
            ]
            # Every shell draws its own wallpaper, tray and notifications.
            ++ lib.optionals (!hasShell) [
              "${pkgs.swaybg}/bin/swaybg -i ~/.config/wallpaper -m fill"
              "${pkgs.networkmanagerapplet}/bin/nm-applet"
              "${pkgs.swaynotificationcenter}/bin/swaync"
            ];

          # Output configuration
          monitor_rule = [
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

          # Border & corner radius. Colours come from DMS's wallpaper theme
          # (sourced in extraConfig), or mango's defaults without DMS.
          border_radius = 8;
          border_px = 3;

          # Gaps
          gap_inner_horizontal = 6;
          gap_inner_vertical = 6;
          gap_outer_horizontal = 10;
          gap_outer_vertical = 10;

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
          # A lone window fills the width instead of sitting centred at 0.5
          scroller_ignore_proportion_single = 0;
          scroller_default_proportion_single = 1.0;

          # Layouts - set all tags to scroller
          tag_rule = map (i: "id:${toString i},layout_name:scroller") (lib.range 1 9);
        }
        // removeAttrs keybindings bindTypes;

      # Binds are written as raw lines so a described bind gets its `# desc`
      # comment directly above it, which DMS's keybind viewer shows.
      extraConfig =
        # DMS regenerates this from the wallpaper and reloads mango. Only the
        # colours are sourced: DMS's other files there (layout, input,
        # outputs) would fight the settings above. Optional because DMS
        # hasn't written it yet on a fresh login.
        lib.optionalString cfg.enableDMS ''
          source_optional = ./dms/colors.conf
        ''
        + lib.concatMapStrings (type:
          lib.concatMapStrings (b:
            if builtins.isAttrs b
            then "# ${b.desc}\n${type} = ${b.bind}\n"
            else "${type} = ${b}\n")
          (keybindings.${type} or []))
        bindTypes;

      # Keep autostart_sh non-empty so the mango hm-module generates the file
      # with systemd/dbus activation. Programs are launched via exec_once in config.conf.
      autostart_sh = ''
        # Programs are started via exec_once in config.conf
      '';
    };

    # Supporting packages
    home.packages = with pkgs;
      [
        adw-gtk3
        grim
        nwg-look
        slurp
        wl-clipboard
        wdisplays
        xwayland-satellite
      ]
      ++ lib.optionals (!hasShell) [
        swaybg
        wofi
        swaynotificationcenter
      ];
  };
}

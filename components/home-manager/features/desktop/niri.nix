{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Utility function for Noctalia IPC commands
  noctaliaBin = "${inputs.noctalia.packages.${pkgs.system}.default}/bin/noctalia-shell";
  noctalia = cmd: [noctaliaBin "ipc" "call"] ++ (pkgs.lib.splitString " " cmd);
in {
  # Note: Don't import inputs.niri.homeModules.niri here - it's already
  # provided by inputs.niri.nixosModules.niri at the system level

  options.components.features.desktop.niri = {
    enable = lib.mkEnableOption "Niri user configuration";
    enableNoctalia = lib.mkEnableOption "Noctalia shell integration with Niri";
  };

  config = lib.mkIf config.components.features.desktop.niri.enable {
    programs.niri = {
      settings = {
        # Input configuration
        input = {
          keyboard = {
            xkb = {
              layout = "us";
              options = "caps:escape";
            };
          };
          touchpad = {
            tap = true;
            natural-scroll = true;
            dwt = true; # Disable while typing
            accel-speed = 0.7;
          };
          mouse = {
            accel-speed = 0.5;
          };
        };

        # Output (monitor) configuration
        outputs = {
          "*" = {
            scale = 1.5;
          };
        };

        # Layout configuration
        layout = {
          gaps = 8;
          center-focused-column = "never";
          preset-column-widths = [
            {proportion = 1.0 / 3.0;}
            {proportion = 1.0 / 2.0;}
            {proportion = 2.0 / 3.0;}
          ];
          default-column-width = {proportion = 1.0 / 2.0;};
          focus-ring = {
            enable = true;
            width = 3;
            active.color = "#1e81b0";
            inactive.color = "#333333";
          };
          border = {
            enable = false;
          };
        };

        # Spawn at startup
        spawn-at-startup =
          [
            {command = ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"];}
            {command = ["${pkgs.networkmanagerapplet}/bin/nm-applet"];}
          ]
          ++ lib.optionals config.components.features.desktop.niri.enableNoctalia [
            {command = [noctaliaBin];}
          ]
          ++ lib.optionals (!config.components.features.desktop.niri.enableNoctalia) [
            {command = ["${pkgs.swaynotificationcenter}/bin/swaync"];}
          ];

        # Prefer server-side decorations
        prefer-no-csd = true;

        # Screenshot path
        screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";

        # Keybindings
        binds = let
          terminal = "${pkgs.ghostty}/bin/ghostty";
        in
          {
            # Application launchers
            "Mod+Return".action.spawn = [terminal];
            "Mod+D".action.spawn = ["${pkgs.wofi}/bin/wofi" "--show" "drun"];
            "Mod+B".action.spawn = ["chromium"];

            # Window management
            "Mod+Q".action.close-window = [];
            "Mod+Shift+E".action.quit = [];

            # Focus movement
            "Mod+H".action.focus-column-left = [];
            "Mod+J".action.focus-window-down = [];
            "Mod+K".action.focus-window-up = [];
            "Mod+L".action.focus-column-right = [];
            "Mod+Left".action.focus-column-left = [];
            "Mod+Down".action.focus-window-down = [];
            "Mod+Up".action.focus-window-up = [];
            "Mod+Right".action.focus-column-right = [];

            # Move windows
            "Mod+Shift+H".action.move-column-left = [];
            "Mod+Shift+J".action.move-window-down = [];
            "Mod+Shift+K".action.move-window-up = [];
            "Mod+Shift+L".action.move-column-right = [];
            "Mod+Shift+Left".action.move-column-left = [];
            "Mod+Shift+Down".action.move-window-down = [];
            "Mod+Shift+Up".action.move-window-up = [];
            "Mod+Shift+Right".action.move-column-right = [];

            # Workspace navigation
            "Mod+1".action.focus-workspace = 1;
            "Mod+2".action.focus-workspace = 2;
            "Mod+3".action.focus-workspace = 3;
            "Mod+4".action.focus-workspace = 4;
            "Mod+5".action.focus-workspace = 5;
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;

            # Move window to workspace
            "Mod+Shift+1".action.move-column-to-workspace = 1;
            "Mod+Shift+2".action.move-column-to-workspace = 2;
            "Mod+Shift+3".action.move-column-to-workspace = 3;
            "Mod+Shift+4".action.move-column-to-workspace = 4;
            "Mod+Shift+5".action.move-column-to-workspace = 5;
            "Mod+Shift+6".action.move-column-to-workspace = 6;
            "Mod+Shift+7".action.move-column-to-workspace = 7;
            "Mod+Shift+8".action.move-column-to-workspace = 8;
            "Mod+Shift+9".action.move-column-to-workspace = 9;

            # Column width adjustments
            "Mod+R".action.switch-preset-column-width = [];
            "Mod+F".action.maximize-column = [];
            "Mod+Shift+F".action.fullscreen-window = [];

            # Column sizing
            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";

            # Scrolling (niri's unique feature)
            "Mod+WheelScrollDown".action.focus-workspace-down = [];
            "Mod+WheelScrollUp".action.focus-workspace-up = [];
            "Mod+Shift+WheelScrollDown".action.move-column-to-workspace-down = [];
            "Mod+Shift+WheelScrollUp".action.move-column-to-workspace-up = [];

            # Screenshots
            "Print".action.screenshot = [];
            "Shift+Print".action.screenshot-window = [];
            "Ctrl+Print".action.screenshot-screen = [];

            # Consume/expel windows from columns
            "Mod+Comma".action.consume-window-into-column = [];
            "Mod+Period".action.expel-window-from-column = [];
          }
          # Noctalia keybindings (when enabled)
          // lib.optionalAttrs config.components.features.desktop.niri.enableNoctalia {
            "Mod+Space".action.spawn = noctalia "launcher toggle";
            "Mod+P".action.spawn = noctalia "sessionMenu toggle";
            "Mod+O".action.spawn = noctalia "overview toggle";
            "Mod+Ctrl+L".action.spawn = noctalia "lockScreen lock";
            "Mod+V".action.spawn = noctalia "launcher clipboard";
            "Mod+E".action.spawn = noctalia "launcher emoji";
            "Mod+Tab".action.spawn = noctalia "launcher windows";
            "Mod+N".action.spawn = noctalia "controlCenter toggle";
            "Mod+C".action.spawn = noctalia "calendar toggle";
            "Mod+Shift+Escape".action.spawn = noctalia "systemMonitor toggle";
            "Mod+Shift+D".action.spawn = noctalia "launcher command";
            "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
            "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
            "XF86AudioMute".action.spawn = noctalia "volume muteOutput";
            "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
            "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";
          };

        # Window rules
        window-rules = [
          {
            matches = [{app-id = "^ghostty$";}];
            opacity = 0.9;
          }
          {
            matches = [{app-id = "^firefox$";}];
            open-maximized = true;
          }
        ];
      };
    };

    # Set DISPLAY for XWayland apps (e.g. IntelliJ, other Java/X11 apps)
    home.sessionVariables = {
      DISPLAY = ":0";
    };

    # Supporting packages
    home.packages = with pkgs;
      [
        wofi
        grim
        slurp
        wl-clipboard
        wdisplays
        xwayland-satellite
      ]
      ++ lib.optionals (!config.components.features.desktop.niri.enableNoctalia) [
        swaynotificationcenter
      ];
  };
}

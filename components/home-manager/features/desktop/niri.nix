{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.features.desktop.niri = {
    enable = lib.mkEnableOption "Niri user configuration";
  };

  config = lib.mkIf config.components.features.desktop.niri.enable {
    programs.niri = {
      enable = true;
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
        spawn-at-startup = [
          {command = ["${pkgs.swaynotificationcenter}/bin/swaync"];}
          {command = ["${pkgs.networkmanagerapplet}/bin/nm-applet"];}
        ];

        # Prefer server-side decorations
        prefer-no-csd = true;

        # Screenshot path
        screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";

        # Keybindings
        binds = let
          terminal = "${pkgs.ghostty}/bin/ghostty";
          menu = "${pkgs.wofi}/bin/wofi --show drun";
        in {
          # Application launchers
          "Mod+Return".action.spawn = [terminal];
          "Mod+D".action.spawn = [menu];

          # Window management
          "Mod+Shift+Q".action = "close-window";
          "Mod+Shift+E".action = "quit";

          # Focus movement
          "Mod+H".action = "focus-column-left";
          "Mod+J".action = "focus-window-down";
          "Mod+K".action = "focus-window-up";
          "Mod+L".action = "focus-column-right";
          "Mod+Left".action = "focus-column-left";
          "Mod+Down".action = "focus-window-down";
          "Mod+Up".action = "focus-window-up";
          "Mod+Right".action = "focus-column-right";

          # Move windows
          "Mod+Shift+H".action = "move-column-left";
          "Mod+Shift+J".action = "move-window-down";
          "Mod+Shift+K".action = "move-window-up";
          "Mod+Shift+L".action = "move-column-right";
          "Mod+Shift+Left".action = "move-column-left";
          "Mod+Shift+Down".action = "move-window-down";
          "Mod+Shift+Up".action = "move-window-up";
          "Mod+Shift+Right".action = "move-column-right";

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
          "Mod+R".action = "switch-preset-column-width";
          "Mod+F".action = "maximize-column";
          "Mod+Shift+F".action = "fullscreen-window";

          # Column sizing
          "Mod+Minus".action = "set-column-width";
          "Mod+Equal".action = "set-column-width";

          # Scrolling (niri's unique feature)
          "Mod+WheelScrollDown".action = "focus-workspace-down";
          "Mod+WheelScrollUp".action = "focus-workspace-up";
          "Mod+Shift+WheelScrollDown".action = "move-column-to-workspace-down";
          "Mod+Shift+WheelScrollUp".action = "move-column-to-workspace-up";

          # Screenshots
          "Print".action = "screenshot";
          "Shift+Print".action = "screenshot-window";
          "Ctrl+Print".action = "screenshot-screen";

          # Consume/expel windows from columns
          "Mod+Comma".action = "consume-window-into-column";
          "Mod+Period".action = "expel-window-from-column";
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

    # Supporting packages
    home.packages = with pkgs; [
      wofi
      swaynotificationcenter
      grim
      slurp
      wl-clipboard
    ];
  };
}

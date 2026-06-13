{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Utility function for Noctalia IPC commands
  noctaliaBin = "${inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/noctalia-shell";
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
            accel-speed = 0.5;
          };
          mouse = {
            accel-speed = 0.5;
          };
        };

        # Output (monitor) configuration
        outputs = {
          "eDP-1" = {
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
        binds = import ./niri-keybindings.nix {
          inherit pkgs noctalia lib;
          enableNoctalia = config.components.features.desktop.niri.enableNoctalia;
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

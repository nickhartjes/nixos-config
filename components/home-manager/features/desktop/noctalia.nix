{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.components.features.desktop.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell configuration";
  };

  config = lib.mkIf config.components.features.desktop.noctalia.enable {
    # Configure Noctalia shell
    programs.noctalia-shell = {
      enable = true;
      # Systemd service disabled - Niri spawns Noctalia directly so it
      # only runs under Niri, not other desktop sessions like Plasma
      systemd.enable = false;

      settings = {
        bar = {
          barType = "simple";
          position = "top";
          density = "default";
          showCapsule = true;
          capsuleOpacity = 1;
          backgroundOpacity = 0.93;
          floating = false;
          marginVertical = 4;
          marginHorizontal = 4;
          frameThickness = 8;
          frameRadius = 12;
          outerCorners = true;
          hideOnOverview = false;
          displayMode = "always_visible";

          widgets = {
            left = [
              {
                id = "ControlCenter";
                useDistroLogo = true;
              }
              {
                id = "Network";
              }
              {
                id = "Bluetooth";
              }
            ];
            center = [
              {
                id = "Workspace";
                hideUnoccupied = false;
                labelMode = "none";
              }
            ];
            right = [
              {
                id = "SystemMonitor";
              }
              {
                id = "Battery";
                alwaysShowPercentage = false;
                warningThreshold = 30;
              }
              {
                id = "Clock";
                formatHorizontal = "HH:mm";
                formatVertical = "HH mm";
                useMonospacedFont = true;
                usePrimaryColor = true;
                timezone = "Europe/Amsterdam";
              }
            ];
          };
        };

        # Color scheme settings
        colorSchemes = {
          preferDark = true;
        };

        # Weather settings
        weather = {
          city = "Arnhem";
        };

        # Overview settings
        overview = {
          showDesktopWidget = true;
        };
      };

      # Theme colors (optional - uses Material 3 colors)
      colors = {
        mError = "#f38ba8";
        mOnError = "#1e1e2e";
        mOnPrimary = "#1e1e2e";
        mOnSecondary = "#1e1e2e";
        mOnSurface = "#cdd6f4";
        mOnSurfaceVariant = "#a6adc8";
        mOnTertiary = "#1e1e2e";
        mOnHover = "#cdd6f4";
        mOutline = "#6c7086";
        mPrimary = "#89b4fa";
        mSecondary = "#f5c2e7";
        mShadow = "#000000";
        mSurface = "#1e1e2e";
        mHover = "#313244";
        mSurfaceVariant = "#181825";
        mTertiary = "#94e2d5";
      };
    };
  };
}

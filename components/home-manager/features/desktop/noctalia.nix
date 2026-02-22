{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.components.features.desktop.noctalia;
  jsonFormat = pkgs.formats.json {};

  # Shared widgets (used by all compositors)
  sharedWidgetsLeft = [
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
    {
      id = "plugin:network-indicator";
    }
    {
      id = "plugin:tailscale";
    }
    {
      id = "plugin:privacy-indicator";
    }
  ];

  sharedWidgetsRight = [
    {
      id = "plugin:mini-docker";
    }
    {
      id = "plugin:pomodoro";
    }
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

  # Base settings shared by all compositors
  mkSettings = {extraCenterWidgets ? []}: {
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
        left = sharedWidgetsLeft;
        center =
          [
            {
              id = "Workspace";
              hideUnoccupied = false;
              labelMode = "none";
            }
          ]
          ++ extraCenterWidgets;
        right = sharedWidgetsRight;
      };
    };

    colorSchemes = {
      preferDark = true;
    };

    weather = {
      city = "Arnhem";
    };

    overview = {
      showDesktopWidget = true;
    };
  };

  niriSettings = mkSettings {};
  mangoSettings = mkSettings {
    extraCenterWidgets = [
      {id = "plugin:mangowc-layout-switcher";}
    ];
  };
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.components.features.desktop.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia-shell = {
      enable = true;
      systemd.enable = false;

      # Default settings (used when no compositor-specific config is copied)
      settings = niriSettings;

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

    # Place compositor-specific settings files
    home.file.".config/noctalia/settings-mango.json".source =
      jsonFormat.generate "noctalia-settings-mango.json" mangoSettings;
    home.file.".config/noctalia/settings-niri.json".source =
      jsonFormat.generate "noctalia-settings-niri.json" niriSettings;
  };
}

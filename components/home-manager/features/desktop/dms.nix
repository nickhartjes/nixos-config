{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  options.components.features.desktop.dms = {
    enable = lib.mkEnableOption "Dank Material Shell configuration";
  };

  config = lib.mkIf config.components.features.desktop.dms.enable {
    programs.dank-material-shell = {
      enable = true;
      # The compositor module turns this on and picks the target (mangowc.nix).
      systemd.enable = lib.mkDefault false;
      enableSystemMonitoring = true;

      # Pinned here, not through the DMS plugin browser, so a fresh host gets
      # them. Names must match the plugin ids in ~/.config/dms/plugin_settings.json,
      # which DMS still manages (enabled flags and settings are set in the GUI).
      plugins = let
        dmsPlugins = pkgs.fetchFromGitHub {
          owner = "AvengeMedia";
          repo = "dms-plugins";
          rev = "a8a508bc371e7c3f2c7862d8840b88cf5c63978f";
          hash = "sha256-3nHfkGzmmq8JpN7bmO8Z5zIumvx8dzwS1GtQ6V0XgMg=";
        };
      in {
        dankBatteryAlerts.src = "${dmsPlugins}/DankBatteryAlerts";
        dankPomodoroTimer.src = "${dmsPlugins}/DankPomodoroTimer";
        amdGpuMonitor.src = pkgs.fetchFromGitHub {
          owner = "navidagz";
          repo = "dms-amd-gpu-monitor";
          rev = "c93a377456c8d69ee2777c306c215d5ceeff9f20";
          hash = "sha256-glQWy3DCZY8y+klcMLUfuyvuO2rath9SynDUBcsdqd4=";
        };
      };
    };

    # DMS looks for these on PATH and the module installs neither: `dgop` for
    # the system-monitor widgets and process list, `amdgpu_top` for the GPU
    # widget (otherwise it fails to spawn it every 4 s and floods the log).
    home.packages = [
      inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.amdgpu_top
    ];
  };
}

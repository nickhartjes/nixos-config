{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.components.features.desktop.noctalia;

  # Noctalia v5 (noctalia-shell) settings. The module renders this attrset to
  # ~/.config/noctalia/config.toml via nixpkgs' TOML formatter, so nested
  # attrsets become [tables] and string lists become arrays.
  #
  # Migrated from the v4 (noctalia-qs) JSON schema. v5 has no plugin system, so
  # the old `plugin:*` widgets (tailscale, pomodoro, mini-docker,
  # network-indicator, privacy-indicator, mangowc-layout-switcher) were dropped.
  # Because those plugins were the only difference between the niri and mango
  # bars, the per-compositor settings split is no longer needed.
  settings = {
    theme = {
      mode = "dark"; # was colorSchemes.preferDark = true
      source = "builtin";
      builtin = "Catppuccin"; # the v4 `colors` block was Catppuccin Mocha hex
    };

    weather = {
      enabled = true;
    };

    location = {
      address = "Arnhem"; # was weather.city
    };

    system.monitor = {
      enabled = true;
    };

    bar.main = {
      position = "top";
      radius = 12; # was frameRadius
      background_opacity = 0.93; # was backgroundOpacity
      capsule = true; # was showCapsule

      # Widget ids per v5 widget_factory; v4 plugin:* widgets dropped.
      start = ["control-center" "network" "bluetooth"];
      center = ["workspaces"];
      end = ["sysmon" "battery" "clock"];
    };
  };
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.components.features.desktop.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      # v5 has no package default; reuse the same package the compositor
      # wrappers spawn.
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
      systemd.enable = false;
      inherit settings;
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.application.browser.firefox;
in {
  options.components.application.browser.firefox.enable = mkEnableOption "enable Firefox browser";

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      # HM 26.05 flipped the default to ${XDG_CONFIG_HOME}/mozilla/firefox.
      # Pinned to legacy so the existing ~/.mozilla/firefox profiles keep
      # working — migrating is a manual `mv` and not worth the churn yet.
      configPath = ".mozilla/firefox";
      package = pkgs.firefox.override {
        cfg = {
          enableGnomeExtensions = true;
        };
      };
    };
  };
}

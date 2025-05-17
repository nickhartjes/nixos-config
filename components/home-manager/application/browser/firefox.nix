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
      package = pkgs.firefox.override {
        cfg = {
          enableGnomeExtensions = true;
        };
      };
    };
  };
}

{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.components.application.browser.librewolf;
in {
  options.components.application.browser.librewolf.enable = mkEnableOption "enable LibreWolf browser";

  config = mkIf cfg.enable {
    programs.librewolf.enable = true;
  };
}

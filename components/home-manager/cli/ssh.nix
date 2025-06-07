{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.ssh;
in {
  options.components.cli.ssh.enable = mkEnableOption "enable ssh";

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
    };
  };
}

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
    services.ssh-agent.enable = true;
    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
    };
  };
}

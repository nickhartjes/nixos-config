{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.virtualization.docker;
in {
  options.components.virtualization.docker.enable = mkEnableOption "enable docker";

  config = mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [
            "--filter=until=24h"
            "--filter=label!=important"
          ];
        };
      };
    };
    networking.extraHosts = ''
      127.0.0.1 host.docker.internal
    '';
    networking.firewall.trustedInterfaces = ["docker0" "br-+"];
    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}

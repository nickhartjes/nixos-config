{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.virtualization.podman;
in {
  options.components.virtualization.podman.enable = mkEnableOption "enable podman";

  config = mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [
            "--filter=until=24h"
            "--filter=label!=important"
          ];
        };
        defaultNetwork.settings.dns_enabled = true;
      };
    };
    environment.systemPackages = with pkgs; [
      podman-compose
    ];
  };
}
# To allow a non-root user to access the Podman socket, add the user
# to the `podman` group in your system users definition. Example:
#
# users.users.<USERNAME> = { # replace <USERNAME> with the actual username
#   extraGroups = [ "podman" ];
# };


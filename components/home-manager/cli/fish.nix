{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.components.cli.fish;
in {
  options.components.cli.fish.enable = mkEnableOption "enable extended fish configuration";

  config = mkIf cfg.enable {
    programs.fish = {
      enable = true;
      loginShellInit = ''
        set -x NIX_PATH nixpkgs=channel:nixos-unstable
        set -x NIX_LOG info

        # Only source secrets if file exists
        if test -f "/run/agenix/${config.home.username}-secrets"
          source /run/agenix/${config.home.username}-secrets
        end

        # Auto-start Hyprland on tty1 if available
        if test (tty) = "/dev/tty1"; and command -q Hyprland
          exec Hyprland &> /dev/null
        end
      '';
      shellAbbrs = {
        ".." = "cd ..";
        "..." = "cd ../..";
        ls = "eza";
        grep = "rg";
        ps = "procs";
      };
    };
  };
}

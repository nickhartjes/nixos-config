{
  config,
  lib,
  pkgs,
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

      interactiveShellInit = ''
        # Set JetBrains JDK
        set -gx BOOT_JDK "${pkgs.jetbrains.jdk}/lib/openjdk"

        # SSH Agent fallback
        if test -z "$SSH_AUTH_SOCK"
          if test -S "$XDG_RUNTIME_DIR/ssh-agent"
            set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent"
          else if test -S "/run/user/(id -u)/ssh-agent"
            set -gx SSH_AUTH_SOCK "/run/user/(id -u)/ssh-agent"
          end
        end

        # fzf shell integration
        fzf --fish | source

        # fastfetch on startup
        fastfetch
      '';

      shellAbbrs = {
        ".." = "cd ..";
        "..." = "cd ../..";
        grep = "rg";
        htop = "btop";
        ps = "procs";
        audit = "sudo lynis audit system";
        ssn = "sudo shutdown now";
        sr = "sudo reboot";
        myip = "curl http://ipecho.net/plain; echo";
        speed = "speedtest-cli --simple";
        pbcopy = "wl-copy || xsel --clipboard --input";
        pbpaste = "wl-paste || xsel --clipboard --output";
      };

      plugins = [
        {
          name = "tide";
          src = pkgs.fishPlugins.tide.src;
        }
        {
          name = "fzf-fish";
          src = pkgs.fishPlugins.fzf-fish.src;
        }
      ];
    };
  };
}

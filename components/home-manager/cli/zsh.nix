{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.zsh;
in {
  options.components.cli.zsh.enable = mkEnableOption "enable zsh";

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autocd = true;
      antidote = {
        enable = true;
        plugins = [
          "zsh-users/zsh-syntax-highlighting"
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-completions"
          "romkatv/powerlevel10k"
          "Aloxaf/fzf-tab"
        ];
      };
      shellAliases = {
        "..." = "cd ../..";
        ".." = "cd ..";
        grep = "rg";
        htop = "btop";
        ps = "procs";
        # Security
        audit = "sudo lynis audit system";

        # Shutdown or reboot
        ssn = "sudo shutdown now";
        sr = "sudo reboot";

        # Information
        myip = "curl http://ipecho.net/plain; echo";
        speed = "speedtest-cli --simple";

        # Clipboard (cross-platform commands)
        pbcopy = "wl-copy || xsel --clipboard --input";
        pbpaste = "wl-paste || xsel --clipboard --output";
      };
      initContent = let
        zshEarlyInit = lib.mkOrder 500 ''
          export NIX_PATH=nixpkgs=channel:nixos-unstable
          export NIX_LOG=info

          # SSH Agent configuration - respect existing SSH_AUTH_SOCK
          if [ -z "$SSH_AUTH_SOCK" ]; then
            # Try to find ssh-agent socket in standard locations
            if [ -S "$XDG_RUNTIME_DIR/ssh-agent" ]; then
              export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
            elif [ -S "/run/user/$(id -u)/ssh-agent" ]; then
              export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent"
            fi
          fi
        '';
        zshGeneralConfig = lib.mkOrder 1000 ''
          # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
          [[ ! -f ~/.config/.p10k.zsh ]] || source ~/.config/.p10k.zsh
          fastfetch
        '';
      in
        lib.mkMerge [zshEarlyInit zshGeneralConfig];
    };

    # Applications needed for the zsh configuration to work properly
    home.packages = with pkgs; [
      btop
      procs
      curl # For myip alias
      speedtest-cli # For speed alias
      xsel # For X11 clipboard
      wl-clipboard # For Wayland clipboard
    ];

    home.file.".config/.p10k.zsh".source = ./files/.p10k.zsh;
  };
}

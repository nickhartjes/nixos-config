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
          "zsh-users/zsh-autosuggestions"
          "zsh-users/zsh-completions"
          "romkatv/powerlevel10k"
          "Aloxaf/fzf-tab"
          "zsh-users/zsh-syntax-highlighting"
          # Optional modern plugin (faster highlighting):
          # "zdharma-continuum/fast-syntax-highlighting"
          # Optional advanced autocomplete:
          # "marlonrichert/zsh-autocomplete"

          # OMZ plugins (antidote syntax)
          # https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
          "ohmyzsh/ohmyzsh path:plugins/aws"
          "ohmyzsh/ohmyzsh path:plugins/command-not-found"
          "ohmyzsh/ohmyzsh path:plugins/gh"
          "ohmyzsh/ohmyzsh path:plugins/git-auto-fetch"
          "ohmyzsh/ohmyzsh path:plugins/git"
          "ohmyzsh/ohmyzsh path:plugins/gradle"
          "ohmyzsh/ohmyzsh path:plugins/kubectl"
          "ohmyzsh/ohmyzsh path:plugins/kubectx"
          "ohmyzsh/ohmyzsh path:plugins/vscode"
        ];
      };

      shellAliases = {
        "..." = "cd ../..";
        ".." = "cd ..";
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

      initContent = ''
        # Source p10k config
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # SSH Agent fallback
        if [ -z "$SSH_AUTH_SOCK" ]; then
          if [ -S "$XDG_RUNTIME_DIR/ssh-agent" ]; then
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
          elif [ -S "/run/user/$(id -u)/ssh-agent" ]; then
            export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent"
          fi
        fi

        # History configuration
        HISTSIZE=5000
        HISTFILE="$HOME/.zsh_history"
        SAVEHIST=$HISTSIZE
        setopt appendhistory
        setopt sharehistory
        setopt hist_ignore_space
        setopt hist_ignore_all_dups
        setopt hist_save_no_dups
        setopt hist_ignore_dups
        setopt hist_find_no_dups

        # Completion improvements
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${LS_COLORS}"

        # fzf-tab preview configuration
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

        # fzf shell integration
        eval "$(fzf --zsh)"

        # zoxide integration (replaces cd with smart cd)
        eval "$(zoxide init --cmd cd zsh)"

        fastfetch
      '';
    };

    home.packages = with pkgs; [
      btop
      procs
      curl
      speedtest-cli
      xsel
      wl-clipboard
      fzf # Added for full integration
      ripgrep # used by alias 'grep=rg'
    ];

    # Powerlevel10k config
    home.file.".p10k.zsh".source = ./files/.p10k.zsh;
  };
}

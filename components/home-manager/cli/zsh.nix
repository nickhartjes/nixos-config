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
      envExtra = ''
        export ZSH_CACHE_DIR="$HOME/.cache/zsh"
        [[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

        # Claude Code's shell snapshot restores zoxide's functions but not its
        # chpwd_functions+= side-effect, so the doctor check spuriously fires
        # in every Bash-tool subshell. Suppress it; the interactive .zshrc is
        # already correctly ordered.
        export _ZO_DOCTOR=0
      '';
      # Plugins come from nixpkgs (hash-pinned through flake.lock), not cloned
      # from GitHub HEAD at shell start. HM sources them at order 900, after
      # oh-my-zsh's compinit (800); fzf-tab must load before autosuggestions,
      # so autosuggestions is a plugin here rather than autosuggestion.enable
      # (which loads at 700).
      plugins = [
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
        }
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
      ];
      syntaxHighlighting.enable = true;

      # https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins
      # Not git-auto-fetch: it runs `git fetch` in any repo you cd into, and an
      # untrusted checkout's .git/config (core.sshCommand, uploadpack) would
      # run as you.
      oh-my-zsh = {
        enable = true;
        plugins = [
          "aws"
          "command-not-found"
          "gh"
          "git"
          "gradle"
          "kubectl"
          "kubectx"
          "vscode"
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
        myip = "curl https://ifconfig.me; echo";
        speed = "speedtest-cli --simple";
        pbcopy = "wl-copy || xsel --clipboard --input";
        pbpaste = "wl-paste || xsel --clipboard --output";
      };

      initContent = mkMerge [
        ''
          # Set JetBrains JDK as BOOT_JDK for Java builds
          export BOOT_JDK="${pkgs.jetbrains.jdk}/lib/openjdk"

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

          fastfetch
        ''

        # Zoxide must be initialized at the very end of .zshrc so its
        # chpwd/precmd hooks wrap (and aren't shadowed by) hooks from
        # mise, kitty, ghostty, etc. Order 2000 places it after HM's
        # shellAliases (which render at order 1100-1150).
        (mkOrder 2000 ''
          eval "$(zoxide init --cmd cd zsh)"
        '')
      ];
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

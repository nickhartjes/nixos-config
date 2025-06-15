{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.ssh;

  # SSH keys to automatically load
  sshKeys = [
    "~/.ssh/id_ed25519"
    "~/.ssh/id_framework-13_2025-06-07"
  ];

  # Script to load SSH keys with improved error handling and logging
  loadKeysScript = pkgs.writeShellScript "load-ssh-keys" ''
    # Function to log messages
    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
    }

    log "Starting SSH key loading process"

    # Check if SSH_AUTH_SOCK is set
    if [ -z "$SSH_AUTH_SOCK" ]; then
      log "ERROR: SSH_AUTH_SOCK not set"
      exit 1
    fi

    # Wait for ssh-agent socket to be available
    timeout=30
    log "Waiting for SSH agent socket: $SSH_AUTH_SOCK"
    while [ $timeout -gt 0 ] && [ ! -S "$SSH_AUTH_SOCK" ]; do
      sleep 1
      timeout=$((timeout - 1))
    done

    if [ ! -S "$SSH_AUTH_SOCK" ]; then
      log "ERROR: SSH agent socket not available after 30 seconds at $SSH_AUTH_SOCK"
      exit 1
    fi

    log "SSH agent socket found at: $SSH_AUTH_SOCK"

    # Check if ssh-agent is responsive
    if ! ${pkgs.openssh}/bin/ssh-add -l >/dev/null 2>&1; then
      if [ $? -eq 2 ]; then
        log "SSH agent is running but has no keys loaded"
      else
        log "ERROR: SSH agent is not responsive"
        exit 1
      fi
    else
      log "SSH agent is responsive and has existing keys"
    fi

    # Load SSH keys
    keys_loaded=0
    keys_failed=0
    ${concatMapStringsSep "\n" (key: ''
        expanded_key=$(eval echo "${key}")
        if [ -f "$expanded_key" ]; then
          log "Loading SSH key: $expanded_key"
          if ${pkgs.openssh}/bin/ssh-add "$expanded_key" 2>/dev/null; then
            log "Successfully loaded: $expanded_key"
            keys_loaded=$((keys_loaded + 1))
          else
            log "Failed to load: $expanded_key (may require passphrase or be invalid)"
            keys_failed=$((keys_failed + 1))
          fi
        else
          log "SSH key not found: $expanded_key"
          keys_failed=$((keys_failed + 1))
        fi
      '')
      sshKeys}

    log "SSH key loading completed: $keys_loaded loaded, $keys_failed failed"

    # List currently loaded keys
    log "Currently loaded keys:"
    ${pkgs.openssh}/bin/ssh-add -l 2>/dev/null || log "No keys currently loaded"
  '';
in {
  options.components.cli.ssh.enable = mkEnableOption "enable ssh";

  config = mkIf cfg.enable {
    services.ssh-agent = {
      enable = true;
    };

    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
      extraConfig = ''
        AddKeysToAgent yes
        IdentitiesOnly yes
        ServerAliveInterval 60
        ServerAliveCountMax 3
      '';
    };

    # Systemd user service to automatically load SSH keys
    systemd.user.services.ssh-add-keys = {
      Unit = {
        Description = "Load SSH keys into ssh-agent";
        After = ["ssh-agent.service" "graphical-session.target"];
        Wants = ["ssh-agent.service"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${loadKeysScript}";
        Environment = [
          "SSH_AUTH_SOCK=%t/ssh-agent"
        ];
        RemainAfterExit = true;
        # Restart on failure
        Restart = "on-failure";
        RestartSec = "10s";
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };

    # Ensure SSH_AUTH_SOCK is available in desktop sessions
    systemd.user.services.ssh-agent-env = {
      Unit = {
        Description = "Set SSH_AUTH_SOCK environment variable for desktop session";
        After = ["ssh-agent.service"];
        Wants = ["ssh-agent.service"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "set-ssh-env" ''
          # Set SSH_AUTH_SOCK for desktop environment
          if [ -n "$XDG_RUNTIME_DIR" ] && [ -S "$XDG_RUNTIME_DIR/ssh-agent" ]; then
            ${pkgs.systemd}/bin/systemctl --user set-environment SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
            echo "SSH_AUTH_SOCK set to: $XDG_RUNTIME_DIR/ssh-agent"
          fi
        ''}";
        RemainAfterExit = true;
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    # Timer to retry loading keys if they fail initially
    systemd.user.timers.ssh-add-keys-retry = {
      Unit = {
        Description = "Retry loading SSH keys";
      };

      Timer = {
        OnStartupSec = "30s";
        OnUnitActiveSec = "5m";
        Unit = "ssh-add-keys.service";
      };

      Install = {
        WantedBy = ["timers.target"];
      };
    };
  };
}

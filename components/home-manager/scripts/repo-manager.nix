{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.scripts.repoManager = {
    enable = lib.mkEnableOption "Repository management automation";

    baseFolder = lib.mkOption {
      type = lib.types.str;
      default = "/home/nh/projects";
      description = "Base directory where project folders will be created";
    };

    repositories = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        nh = [
          "git@github.com:nickhartjes/obsidian.git"
          "git@github.com:nickhartjes/talos.git"
          "git@github.com:nickhartjes/gitops.git"
          "git@github.com:nickhartjes/codex.git"
          "git@github.com:nickhartjes/nickhartjes.nl.git"
        ];
        dealdodo = [
          "git@github.com:dealdodo/frontend"
          "git@github.com:dealdodo/backend"
        ];
      };
      description = "Repository groups and their URLs";
    };
  };

  config = lib.mkIf config.components.scripts.repoManager.enable {
    home.packages = with pkgs; [
      git
      libnotify # for notifications
    ];

    # Create the repository management script
    home.file.".local/bin/repo-manager" = {
      text = ''
        #!/usr/bin/env bash

        BASE_FOLDER="${config.components.scripts.repoManager.baseFolder}"
        LOG_FILE="$HOME/.local/state/repo-manager.log"

        # Create log directory if it doesn't exist
        mkdir -p "$(dirname "$LOG_FILE")"

        # Function to log messages
        log() {
          echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
        }

        # Function to send notification
        notify() {
          ${pkgs.libnotify}/bin/notify-send "Repository Manager" "$1"
        }

        # Function to clone or fetch repositories
        clone_or_fetch() {
          local folder_name=$1
          shift
          local repos=("$@")

          local full_path="$BASE_FOLDER/$folder_name"

          log "Processing folder: $folder_name"
          mkdir -p "$full_path"
          cd "$full_path"

          local success_count=0
          local error_count=0

          for repo_url in "''${repos[@]}"; do
            local repo_name=$(echo "$repo_url" | awk -F'/' '{print $NF}' | sed 's/.git$//')

            if [ -d "$repo_name" ]; then
              log "Repository $repo_name already exists in $folder_name, fetching updates..."
              if (cd "$repo_name" && git fetch 2>&1 | tee -a "$LOG_FILE"); then
                ((success_count++))
                log "Successfully fetched updates for $repo_name"
              else
                ((error_count++))
                log "ERROR: Failed to fetch updates for $repo_name"
              fi
            else
              log "Cloning repository $repo_name into $folder_name..."
              if git clone "$repo_url" 2>&1 | tee -a "$LOG_FILE"; then
                ((success_count++))
                log "Successfully cloned $repo_name"
              else
                ((error_count++))
                log "ERROR: Failed to clone $repo_name"
              fi
            fi
          done

          log "Completed $folder_name: $success_count successful, $error_count failed"
          return $error_count
        }

        # Main execution
        log "Starting repository management process"
        total_errors=0

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (folderName: repoList: ''
            clone_or_fetch "${folderName}" ${lib.concatStringsSep " " (map (repo: ''"${repo}"'') repoList)}
            total_errors=$((total_errors + $?))
          '')
          config.components.scripts.repoManager.repositories)}

        if [ $total_errors -eq 0 ]; then
          log "Repository management completed successfully"
          notify "All repositories updated successfully!"
        else
          log "Repository management completed with $total_errors errors"
          notify "Repository update completed with $total_errors errors. Check log for details."
        fi
      '';
      executable = true;
    };

    # Create systemd user service
    systemd.user.services.repo-manager = {
      Unit = {
        Description = "Repository Management Service";
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "%h/.local/bin/repo-manager";
        Environment = [
          "PATH=${lib.makeBinPath (with pkgs; [git openssh libnotify coreutils gawk gnused])}"
        ];
      };
    };

    # Create systemd timer for daily execution
    systemd.user.timers.repo-manager = {
      Unit = {
        Description = "Repository Management Timer";
        Requires = ["repo-manager.service"];
      };

      Timer = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "15m";
      };

      Install = {
        WantedBy = ["timers.target"];
      };
    };

    # Enable the timer
    systemd.user.startServices = true;
  };
}

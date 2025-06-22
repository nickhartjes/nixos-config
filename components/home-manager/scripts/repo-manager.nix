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
      default = "$HOME/projects";
      description = "Base directory where project folders will be created";
    };

    repositories = lib.mkOption {
      type = lib.types.submodule {
        options = {
          global = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            default = {};
            description = "Global repository groups available to all users";
            example = {
              tools = [
                "git@github.com:company/cli-tools.git"
                "git@github.com:company/shared-scripts.git"
              ];
              documentation = [
                "git@github.com:company/docs.git"
              ];
            };
          };

          users = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf (lib.types.listOf lib.types.str));
            default = {};
            description = "User-specific repository groups";
            example = {
              alice = {
                personal = [
                  "git@github.com:alice/personal-project.git"
                ];
                work = [
                  "git@github.com:company/alice-work.git"
                ];
              };
              bob = {
                experiments = [
                  "git@github.com:bob/experiment1.git"
                  "git@github.com:bob/experiment2.git"
                ];
              };
            };
          };
        };
      };
      default = {};
      description = "Repository configuration with global and per-user groups";
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

        # Get current user
        CURRENT_USER=$(whoami)

        # Main execution
        log "Starting repository management process for user: $CURRENT_USER"
        total_errors=0

        # Process global repositories
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (folderName: repoList: ''
            clone_or_fetch "${folderName}" ${lib.concatStringsSep " " (map (repo: ''"${repo}"'') repoList)}
            total_errors=$((total_errors + $?))
          '')
          config.components.scripts.repoManager.repositories.global)}

        # Process user-specific repositories if they exist
        ${lib.optionalString (config.components.scripts.repoManager.repositories.users != {}) ''
          case "$CURRENT_USER" in
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (userName: userRepos: ''
            "${userName}")
              log "Processing user-specific repositories for ${userName}"
              ${lib.concatStringsSep "\n" (lib.mapAttrsToList (folderName: repoList: ''
                clone_or_fetch "${folderName}" ${lib.concatStringsSep " " (map (repo: ''"${repo}"'') repoList)}
                total_errors=$((total_errors + $?))
              '')
              userRepos)}
              ;;'')
          config.components.scripts.repoManager.repositories.users)}
            *)
              log "No user-specific repositories configured for user: $CURRENT_USER"
              ;;
          esac
        ''}

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

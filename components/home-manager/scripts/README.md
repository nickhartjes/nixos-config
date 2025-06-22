# Repository Manager

A NixOS/Home Manager module for automated repository management with per-user configuration support.

## Overview

The Repository Manager automatically clones and updates Git repositories based on configurable groups. It supports both global repositories (available to all users) and user-specific repositories that are only processed when the corresponding user runs the script.

## Features

- **Global Repositories**: Define repositories that all users can access
- **Per-User Configuration**: Each user can have their own repository groups
- **Automatic Updates**: Daily systemd timer automatically fetches updates
- **Logging**: Comprehensive logging to `~/.local/state/repo-manager.log`
- **Notifications**: Desktop notifications on completion
- **Error Handling**: Continues processing even if individual repositories fail

## Configuration

### Basic Setup

Enable the repository manager in your Home Manager configuration:

```nix
{
  components.scripts.repoManager = {
    enable = true;
    
    # Optional: customize base directory (default: $HOME/projects)
    baseFolder = "$HOME/dev";
    
    repositories = {
      global = {
        # Global repositories available to all users
        tools = [
          "git@github.com:useful/cli-tool.git"
          "git@github.com:company/shared-lib.git"
        ];
      };
      
      users = {
        # User-specific repositories
        alice = {
          personal = [
            "git@github.com:alice/dotfiles.git"
            "git@github.com:alice/blog.git"
          ];
          work = [
            "git@github.com:company/alice-project.git"
          ];
        };
      };
    };
  };
}
```

### Repository Structure

The repository configuration supports two levels:

1. **Global Repositories** (`repositories.global`): Available to all users
2. **User-Specific Repositories** (`repositories.users.<username>`): Only processed when that specific user runs the script

### Directory Organization

Repositories are organized in the following structure:

```
<baseFolder>/
├── <group-name-1>/
│   ├── <repo-1>/
│   └── <repo-2>/
├── <group-name-2>/
│   ├── <repo-3>/
│   └── <repo-4>/
└── ...
```

For example, with the configuration above:

```
/home/alice/dev/
├── tools/
│   ├── cli-tool/
│   └── shared-lib/
├── personal/
│   ├── dotfiles/
│   └── blog/
└── work/
    └── alice-project/
```

## Usage

### Manual Execution

Run the repository manager manually:

```bash
~/.local/bin/repo-manager
```

### Automatic Execution

The repository manager runs automatically via a systemd timer:

- **Schedule**: Daily
- **Randomized Delay**: Up to 15 minutes to avoid system load spikes
- **Persistent**: Runs missed executions when the system comes online

### Managing the Service

```bash
# Check service status
systemctl --user status repo-manager.service

# Check timer status
systemctl --user status repo-manager.timer

# View logs
journalctl --user -u repo-manager.service

# Manual trigger
systemctl --user start repo-manager.service
```

## Behavior

### For Existing Repositories
- Performs `git fetch` to update remote references
- Does not modify working directory or current branch
- Logs success/failure of each fetch operation

### For New Repositories
- Clones the repository using the provided URL
- Creates directory structure as needed
- Logs success/failure of each clone operation

### User Detection
- Automatically detects the current user using `whoami`
- Processes global repositories for all users
- Only processes user-specific repositories for the current user
- Logs when no user-specific configuration is found

## Logging and Notifications

### Log File
- Location: `~/.local/state/repo-manager.log`
- Format: `YYYY-MM-DD HH:MM:SS - <message>`
- Includes: Start/completion times, repository operations, errors

### Notifications
- Success: "All repositories updated successfully!"
- Errors: "Repository update completed with X errors. Check log for details."

## Advanced Configuration

### Multiple Users Example

```nix
{
  components.scripts.repoManager = {
    enable = true;
    repositories = {
      global = {
        shared = [
          "git@github.com:company/shared-tools.git"
          "git@github.com:company/documentation.git"
        ];
      };
      users = {
        developer1 = {
          frontend = [
            "git@github.com:company/web-app.git"
            "git@github.com:company/mobile-app.git"
          ];
          personal = [
            "git@github.com:developer1/portfolio.git"
          ];
        };
        developer2 = {
          backend = [
            "git@github.com:company/api-server.git"
            "git@github.com:company/database-migrations.git"
          ];
          experiments = [
            "git@github.com:developer2/ml-project.git"
          ];
        };
      };
    };
  };
}
```

### Custom Base Directory

```nix
{
  components.scripts.repoManager = {
    enable = true;
    baseFolder = "/home/username/code";  # Custom location
    # ... repositories configuration
  };
}
```

## Troubleshooting

### Common Issues

1. **SSH Key Authentication**: Ensure SSH keys are properly configured for Git hosts
2. **Directory Permissions**: Verify write access to the base folder
3. **Network Connectivity**: Check internet connection for repository access

### Debugging

1. Check the log file: `cat ~/.local/state/repo-manager.log`
2. Run manually with verbose output: `~/.local/bin/repo-manager`
3. Check systemd service logs: `journalctl --user -u repo-manager.service -f`

### Service Management

```bash
# Restart the timer
systemctl --user restart repo-manager.timer

# Disable automatic execution
systemctl --user disable repo-manager.timer

# Re-enable automatic execution
systemctl --user enable repo-manager.timer
```

## Migration from Previous Versions

If you're migrating from a previous version that used a flat repository structure, update your configuration:

**Old format:**
```nix
repositories = {
  group1 = ["repo1", "repo2"];
  group2 = ["repo3"];
};
```

**New format:**
```nix
repositories = {
  global = {
    group1 = ["repo1", "repo2"];
    group2 = ["repo3"];
  };
  users = {
    # Add user-specific repositories here
  };
};
```

The migration is backward compatible - existing repository groups will be treated as global repositories.

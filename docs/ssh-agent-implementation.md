# SSH Agent Implementation - Installation and Testing Guide

## Overview

This implementation fixes the SSH agent configuration issues in your NixOS setup. The main problems addressed:

1. **SSH_AUTH_SOCK conflict** between ZSH and systemd service
2. **macOS-specific settings** that don't work on Linux
3. **Hardcoded user ID** assumptions in socket paths
4. **Improved error handling** and logging for debugging

## Changes Made

### 1. Fixed SSH Configuration ([`components/home-manager/cli/ssh.nix`](../components/home-manager/cli/ssh.nix))

**Key improvements:**
- ✅ Removed macOS-specific `UseKeychain yes` setting
- ✅ Enhanced key loading script with comprehensive logging
- ✅ Added proper error handling and key validation
- ✅ Improved systemd service configuration with desktop integration
- ✅ Added restart capability for failed services
- ✅ Added environment variable propagation for desktop sessions

### 2. Fixed ZSH Configuration ([`components/home-manager/cli/zsh.nix`](../components/home-manager/cli/zsh.nix))

**Key improvements:**
- ✅ Removed hardcoded `SSH_AUTH_SOCK=/run/user/1001/ssh-agent`
- ✅ Added intelligent SSH agent detection using dynamic user ID
- ✅ Respects existing SSH_AUTH_SOCK if already set
- ✅ Fallback logic for finding SSH agent socket

### 3. Added Testing Tools

**New files:**
- ✅ [`scripts/test-ssh-agent.sh`](../scripts/test-ssh-agent.sh) - Comprehensive SSH agent testing script
- ✅ [`docs/ssh-agent-fix-plan.md`](ssh-agent-fix-plan.md) - Detailed analysis and planning documentation

## Installation Steps

### Step 1: Apply the Configuration

Rebuild your NixOS configuration to apply the changes:

```bash
# Apply the changes
sudo nixos-rebuild switch --flake .

# Or if you prefer to test first
sudo nixos-rebuild test --flake .
```

### Step 2: Restart User Services

After rebuilding, restart the SSH-related systemd user services:

```bash
# Restart SSH agent services
systemctl --user restart ssh-agent
systemctl --user restart ssh-add-keys
systemctl --user restart ssh-agent-env

# Check service status
systemctl --user status ssh-agent ssh-add-keys ssh-agent-env
```

### Step 3: Reload Shell Environment

Start a new shell session or reload your shell configuration:

```bash
# Option 1: Start a new shell session
exec zsh

# Option 2: Source your shell configuration
source ~/.zshrc
```

## Testing and Validation

### Quick Test

Run the comprehensive test script:

```bash
./scripts/test-ssh-agent.sh
```

This script will check:
- ✅ Environment variables (SSH_AUTH_SOCK)
- ✅ Systemd service status
- ✅ SSH agent communication
- ✅ SSH key file existence and permissions
- ✅ Provide troubleshooting guidance

### Manual Verification Steps

1. **Check SSH_AUTH_SOCK is set correctly:**
   ```bash
   echo $SSH_AUTH_SOCK
   # Should show: /run/user/$(id -u)/ssh-agent
   ```

2. **Verify SSH agent is responsive:**
   ```bash
   ssh-add -l
   # Should list your SSH keys or show "The agent has no identities loaded."
   ```

3. **Check systemd services are running:**
   ```bash
   systemctl --user is-active ssh-agent ssh-add-keys ssh-agent-env
   # All should show "active"
   ```

4. **Test SSH connectivity:**
   ```bash
   # Test with GitHub (if you have access)
   ssh -T git@github.com
   
   # Test with your servers
   ssh your-server.com
   ```

## Troubleshooting

### If SSH Agent Still Doesn't Work

1. **Check service logs:**
   ```bash
   journalctl --user -u ssh-add-keys -f
   journalctl --user -u ssh-agent -f
   ```

2. **Manually restart services:**
   ```bash
   systemctl --user stop ssh-agent ssh-add-keys ssh-agent-env
   systemctl --user start ssh-agent ssh-add-keys ssh-agent-env
   ```

3. **Verify key files exist and have correct permissions:**
   ```bash
   ls -la ~/.ssh/id_ed25519 ~/.ssh/id_framework-13_2025-06-07
   chmod 600 ~/.ssh/id_ed25519 ~/.ssh/id_framework-13_2025-06-07
   ```

### If Keys Still Require Passphrase

If your SSH keys are password-protected and you want to enter the passphrase once per session:

```bash
# Manually add keys with passphrase
ssh-add ~/.ssh/id_ed25519
ssh-add ~/.ssh/id_framework-13_2025-06-07

# Verify keys are loaded
ssh-add -l
```

### Desktop Environment Issues

If you're using KDE Plasma and experiencing conflicts:

1. **Disable KDE's SSH agent (if needed):**
   ```bash
   # Check if KDE is managing SSH agent
   ps aux | grep ssh-agent
   
   # If there are multiple ssh-agent processes, you may need to configure KDE
   # to not start its own SSH agent
   ```

2. **Set environment variables for desktop session:**
   ```bash
   systemctl --user set-environment SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
   ```

## Expected Behavior After Fix

✅ **SSH keys automatically load** when you log in  
✅ **No password prompts** for SSH connections (after initial key loading)  
✅ **Consistent SSH_AUTH_SOCK** across all shell sessions  
✅ **Desktop environment integration** works properly  
✅ **Robust error handling** with helpful logging  
✅ **Cross-session persistence** - works after reboot  

## Rollback Instructions

If you need to revert the changes:

```bash
# Revert git changes
git checkout HEAD~1 -- components/home-manager/cli/ssh.nix components/home-manager/cli/zsh.nix

# Rebuild configuration
sudo nixos-rebuild switch --flake .

# Restart services
systemctl --user restart ssh-agent
```

## Additional Resources

- [NixOS SSH Agent Documentation](https://nixos.wiki/wiki/SSH_public_key_authentication)
- [Home Manager SSH Options](https://nix-community.github.io/home-manager/options.html#opt-programs.ssh.enable)
- [Systemd User Services](https://wiki.archlinux.org/title/Systemd/User)

## Support

If you encounter issues after following this guide:

1. Run `./scripts/test-ssh-agent.sh` and share the output
2. Check `journalctl --user -u ssh-add-keys` for detailed logs
3. Verify your SSH key files exist and have correct permissions
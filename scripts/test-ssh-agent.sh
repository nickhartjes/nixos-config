#!/usr/bin/env bash

# SSH Agent Test Script
# This script validates the SSH agent configuration and provides debugging information

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}✗${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
    esac
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_header "SSH Agent Configuration Test"

# Check if SSH_AUTH_SOCK is set
print_header "Environment Variables"
if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    print_status "OK" "SSH_AUTH_SOCK is set: $SSH_AUTH_SOCK"
    
    # Check if socket exists
    if [ -S "$SSH_AUTH_SOCK" ]; then
        print_status "OK" "SSH agent socket exists and is accessible"
    else
        print_status "ERROR" "SSH agent socket does not exist or is not accessible"
    fi
else
    print_status "ERROR" "SSH_AUTH_SOCK is not set"
    print_status "INFO" "Try: export SSH_AUTH_SOCK=\$XDG_RUNTIME_DIR/ssh-agent"
fi

# Check systemd user services
print_header "Systemd User Services"
services=("ssh-agent" "ssh-add-keys" "ssh-agent-env")

for service in "${services[@]}"; do
    if systemctl --user is-active --quiet "$service" 2>/dev/null; then
        print_status "OK" "$service.service is active"
    else
        status=$(systemctl --user is-active "$service" 2>/dev/null || echo "inactive")
        print_status "WARN" "$service.service is $status"
        
        # Show recent logs for failed services
        if [ "$status" = "failed" ]; then
            print_status "INFO" "Recent logs for $service:"
            systemctl --user status "$service" --no-pager -l -n 5 || true
        fi
    fi
done

# Test SSH agent communication
print_header "SSH Agent Communication"
if command -v ssh-add >/dev/null 2>&1; then
    if ssh-add -l >/dev/null 2>&1; then
        key_count=$(ssh-add -l 2>/dev/null | wc -l)
        print_status "OK" "SSH agent is responsive with $key_count key(s) loaded"
        
        # List loaded keys
        print_status "INFO" "Loaded keys:"
        ssh-add -l 2>/dev/null | while IFS= read -r line; do
            echo "  $line"
        done
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            print_status "WARN" "SSH agent is responsive but has no keys loaded"
        else
            print_status "ERROR" "SSH agent is not responsive (exit code: $exit_code)"
        fi
    fi
else
    print_status "ERROR" "ssh-add command not found"
fi

# Check for SSH key files
print_header "SSH Key Files"
ssh_keys=(
    "$HOME/.ssh/id_ed25519"
    "$HOME/.ssh/id_framework-13_2025-06-07"
)

for key in "${ssh_keys[@]}"; do
    if [ -f "$key" ]; then
        print_status "OK" "SSH key exists: $key"
        
        # Check permissions
        perms=$(stat -c "%a" "$key" 2>/dev/null || echo "unknown")
        if [ "$perms" = "600" ]; then
            print_status "OK" "SSH key permissions are correct (600)"
        else
            print_status "WARN" "SSH key permissions are $perms (should be 600)"
            print_status "INFO" "Fix with: chmod 600 $key"
        fi
    else
        print_status "WARN" "SSH key not found: $key"
    fi
done

# Test SSH connectivity (optional)
print_header "SSH Connectivity Test"
echo "To test SSH connectivity to a server, run:"
echo "  ssh -T git@github.com  # For GitHub"
echo "  ssh your-server.com    # For your servers"

print_header "Troubleshooting Commands"
echo "If SSH agent is not working, try:"
echo "  systemctl --user restart ssh-agent ssh-add-keys ssh-agent-env"
echo "  journalctl --user -u ssh-add-keys -f  # View logs"
echo "  nixos-rebuild switch --flake .        # Apply configuration changes"

print_header "Test Complete"
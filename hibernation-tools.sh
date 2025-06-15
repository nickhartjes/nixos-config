#!/bin/bash

# Hibernation Management Tools for Framework 13

case "$1" in
    "test")
        echo "Testing hibernation..."
        echo "This will hibernate your system. Make sure to save your work!"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl hibernate
        else
            echo "Hibernation test cancelled."
        fi
        ;;
    
    "check")
        echo "=== Hibernation Setup Verification ==="
        echo
        echo "1. Swap status:"
        swapon --show
        echo
        echo "2. Resume configuration:"
        echo "Current kernel resume params: $(cat /proc/cmdline | grep -o 'resume[^ ]*')"
        echo "Resume offset in /sys: $(cat /sys/power/resume_offset 2>/dev/null || echo 'Not set')"
        echo
        echo "3. Hibernation capabilities:"
        echo "Available modes: $(cat /sys/power/disk 2>/dev/null || echo 'Not available')"
        echo "Current mode: $(cat /sys/power/disk 2>/dev/null | grep -o '\[.*\]' || echo 'Not available')"
        echo
        echo "4. Power management status:"
        echo "Power profiles daemon: $(systemctl is-active power-profiles-daemon)"
        echo "Powertop service: $(systemctl is-active powertop)"
        echo
        ;;
    
    "suspend-test")
        echo "Testing suspend-then-hibernate..."
        echo "System will suspend, then hibernate after 30 minutes."
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            systemctl suspend-then-hibernate
        else
            echo "Suspend-then-hibernate test cancelled."
        fi
        ;;
    
    "status")
        echo "=== Power Management Status ==="
        echo "Current power profile: $(powerprofilesctl get 2>/dev/null || echo 'Not available')"
        echo "Available profiles: $(powerprofilesctl list 2>/dev/null || echo 'Not available')"
        echo
        echo "Logind configuration:"
        echo "Lid switch: $(systemctl show systemd-logind --property=HandleLidSwitch --value)"
        echo "Power key: $(systemctl show systemd-logind --property=HandlePowerKey --value)"
        echo
        echo "Current CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'Not available')"
        ;;
    
    "power-save")
        echo "Switching to power-save profile..."
        powerprofilesctl set power-saver 2>/dev/null && echo "Switched to power-saver profile" || echo "Failed to switch profile"
        ;;
    
    "performance")
        echo "Switching to performance profile..."
        powerprofilesctl set performance 2>/dev/null && echo "Switched to performance profile" || echo "Failed to switch profile"
        ;;
    
    "balanced")
        echo "Switching to balanced profile..."
        powerprofilesctl set balanced 2>/dev/null && echo "Switched to balanced profile" || echo "Failed to switch profile"
        ;;
    
    "log")
        echo "=== Recent hibernation/suspend logs ==="
        journalctl -u systemd-logind --since "24 hours ago" | grep -i "suspend\|hibernate" | tail -20
        ;;
    
    *)
        echo "Hibernation Management Tools for Framework 13"
        echo
        echo "Usage: $0 {command}"
        echo
        echo "Commands:"
        echo "  check         - Verify hibernation setup"
        echo "  test          - Test hibernation (will hibernate system)"
        echo "  suspend-test  - Test suspend-then-hibernate"
        echo "  status        - Show power management status"
        echo "  power-save    - Switch to power-saver profile"
        echo "  performance   - Switch to performance profile"
        echo "  balanced      - Switch to balanced profile"
        echo "  log           - Show recent hibernation logs"
        echo
        echo "Examples:"
        echo "  $0 check      # Verify hibernation is working"
        echo "  $0 test       # Test hibernation"
        echo "  $0 status     # Check power management status"
        ;;
esac

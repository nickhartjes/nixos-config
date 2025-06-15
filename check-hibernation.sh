#!/bin/bash

echo "=== Hibernation Setup Verification ==="
echo

echo "1. Checking swap status:"
swapon --show
echo

echo "2. Checking resume device configuration:"
echo "Resume device: $(cat /sys/power/resume_device 2>/dev/null || echo 'Not set')"
echo "Resume offset: $(cat /sys/power/resume_offset 2>/dev/null || echo 'Not set')"
echo

echo "3. Current kernel command line:"
cat /proc/cmdline | grep -o 'resume[^ ]*'
echo

echo "4. Expected configuration:"
echo "Resume device should be: /dev/mapper/cryptroot"
echo "Resume offset should be: 2957497"
echo

echo "5. Testing hibernation capability:"
if [[ -f /sys/power/disk ]]; then
    echo "Available hibernation modes: $(cat /sys/power/disk)"
    echo "Current hibernation mode: $(cat /sys/power/disk | grep -o '\[.*\]')"
else
    echo "Hibernation not supported by kernel"
fi
echo

echo "6. Checking if swapfile is properly configured for hibernation:"
if [[ -f /swap/swapfile ]]; then
    echo "Swapfile exists: /swap/swapfile"
    ls -lh /swap/swapfile
    echo "Swapfile offset: $(sudo btrfs inspect-internal map-swapfile -r /swap/swapfile 2>/dev/null || echo 'Failed to get offset')"
else
    echo "Swapfile not found at /swap/swapfile"
fi

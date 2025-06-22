# Desktop Configuration

This directory contains desktop environment related configurations.

## Plasma Configuration

KDE Plasma configuration is now handled directly in the user configuration (`users/nh.nix`) using plasma-manager.

### Features Configured:
- Breeze Dark theme
- Basic keyboard shortcuts (Meta+1-4 for desktop switching, Meta+Return for terminal, etc.)
- Default applications (Firefox for browser, Konsole for terminal)
- Essential KDE applications installed

### To Extend:
You can add more plasma-manager configuration options directly in the `programs.plasma` section of your user configuration. See [plasma-manager documentation](https://github.com/nix-community/plasma-manager) for available options.

## Other Desktop Components:
- **fonts.nix**: Font configuration for desktop applications

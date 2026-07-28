# Enable KDE Plasma on framework-13

**Date:** 2026-07-28
**Status:** Approved

## Goal

Replace COSMIC with KDE Plasma 6 as the desktop environment on the
framework-13 host, using SDDM as the display manager.

## Context

- The repo already has a `components.desktop.plasma` module
  (`components/nixos/desktop-manager/plasma.nix`) — it is just disabled
  on every host.
- Home-manager already carries an active `programs.plasma`
  (plasma-manager) config in `users/nh/desktop.nix` with shortcuts,
  virtual desktops, and theme settings. No HM changes are needed.
- `components/nixos/desktop-manager/default.nix` asserts that at most
  one full DE is enabled, so COSMIC must be turned off.
- `components/nixos/display-manager/default.nix` centrally force-sets
  every DM from its `components.display.*` flag, so switching the flags
  is sufficient to swap cosmic-greeter for SDDM.

## Changes

### `hosts/framework-13/default.nix`

1. `components.desktop.cosmic.enable = false`
2. `components.desktop.plasma.enable = true`
3. `components.display.cosmic-greeter.enable = false`
4. `components.display.sddm.enable = true`
5. `services.displayManager.defaultSession = lib.mkForce "plasma"`
   (Plasma 6 Wayland session name; replaces the current `"cosmic"`)

mangowc and niri stay enabled — they are window managers, not full
DEs, and remain selectable from the SDDM session picker.

### `components/nixos/display-manager/sddm.nix`

The module currently only declares its enable option. Add:

```nix
config = lib.mkIf config.components.display.sddm.enable {
  services.displayManager.sddm.wayland.enable = lib.mkDefault true;
};
```

so SDDM runs its greeter on Wayland instead of spawning an X11 server.
`mkDefault` keeps it overridable per host.

## Out of scope

- No changes to `plasma.nix` (pipewire, NetworkManager, and the KDE
  app set there are already fine).
- No changes to home-manager / plasma-manager config.
- No changes to other hosts.

## Verification

- `nixos-rebuild build --flake .#framework-13` succeeds (this also
  exercises the one-DE and one-DM assertions).
- Manual: after `switch` + reboot, SDDM appears, the Plasma (Wayland)
  session is default, and the plasma-manager shortcuts (Meta+1..4,
  Meta+Return for ghostty) work.

## Rollback

Flip the four booleans and the session name back. No state migration
involved.

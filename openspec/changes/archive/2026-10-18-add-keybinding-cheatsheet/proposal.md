## Why

Omarchy has a one-key cheat sheet for every binding (Super+K). With three compositors and ~100 custom bindings in mango and niri alone, the only way to look up a binding here is to read the Nix files.

## What Changes

- Super+Shift+/ (the "?" key) shows the current session's keybindings, in both mango and niri.
- mango uses the keybinds viewer built into DMS, the shell that session runs. niri uses its native hotkey overlay. No custom tool is written.
- Custom niri bindings get human-readable titles so they show up meaningfully in the overlay.

## Capabilities

### New Capabilities
- `keybinding-help`: An on-screen reference of the active session's keybindings, opened by a single shortcut.

### Modified Capabilities

## Impact

- `components/home-manager/features/desktop/mangowc-keybindings.nix`, `components/home-manager/features/desktop/niri-keybindings.nix`.
- Relies on DMS's `keybinds` IPC (present in dms-shell 1.7-beta) and niri's `show-hotkey-overlay` action. No new dependencies.

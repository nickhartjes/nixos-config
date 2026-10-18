## Why

Colors are set per application today: Catppuccin Mocha is hardcoded in ghostty, VS Code, k9s and mango's borders, and other apps use their own defaults. Omarchy applies one theme to everything at once. The user chose Tokyo Night as the single scheme.

## What Changes

- Add Stylix as a flake input, on framework-13 only.
- Apply Tokyo Night (dark) to terminals, Neovim, VS Code, k9s, lazygit, and mango and niri window borders. GTK and btop are skipped: Plasma/DMS/nwg-look own and rewrite the GTK files (and the Stylix GTK target changes font, icon and cursor settings), and btop is not HM-managed and rewrites its own `btop.conf`.
- Remove the per-app Catppuccin settings that Stylix replaces (fallbacks stay for hosts without Stylix; VS Code keeps `catppuccin-vsc-icons`, and the Stylix color theme is selected once by hand in VS Code).
- **Out of scope:** fonts (they stay Comic Code at today's sizes), wallpapers, Plasma/Qt theming (plasma-manager owns it), DMS/Noctalia themes (they have their own engines), and switching themes by hotkey.
- **BREAKING (visual):** every themed app changes from Catppuccin to Tokyo Night colors.

## Capabilities

### New Capabilities
- `desktop-theming`: A single color scheme applied consistently across nh's terminal, editor, TUI, GTK and compositor surfaces.

### Modified Capabilities

## Impact

- New flake input `stylix` (follows nixpkgs) and its NixOS module in framework-13's module list; `flake.lock` changes.
- New `components/nixos/system/stylix.nix` and `components/home-manager/features/desktop/stylix.nix`; the mango and niri border color overrides live in the latter, so `mangowc.nix` and `niri.nix` are unchanged.
- Edits to `terminal/ghostty.nix`, `development/editor/vscode.nix`, `development/infrastructure/k9s.nix`, `users/nh/desktop.nix`, `hosts/framework-13/default.nix`.

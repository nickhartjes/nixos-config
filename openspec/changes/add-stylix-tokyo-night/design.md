## Context

Theme settings are scattered: ghostty `theme = "Catppuccin Mocha"`, VS Code Catppuccin extensions, a k9s Catppuccin skin, Catppuccin hex values for mango borders (`focus_color = 0x89b4faff` etc.), and a Noctalia Catppuccin preset. Fonts are "ComicCodeLigatures Nerd Font" from `pkgs/fonts-custom`, at size 10 in ghostty and 7 in alacritty. `home-manager.useGlobalPkgs` is off in this repo. Plasma 6 plus plasma-manager is installed on framework-13.

## Goals / Non-Goals

**Goals:** one scheme setting drives every listed surface; no visual change besides colors.

**Non-Goals:** runtime theme switching; theming DMS/Noctalia (they theme themselves, and DMS can follow the wallpaper); Plasma/Qt; fonts; wallpapers.

## Decisions

- **Stylix over hand-rolled base16 templates or per-app Tokyo Night themes.** Stylix already has targets for most surfaces and exposes `config.lib.stylix.colors` for the rest (mango, and niri if it has no target). Per-app themes would recreate today's scattering.
- **NixOS module on framework-13 only**, auto-injected into Home Manager. Other hosts never import Stylix, which keeps servers and VMs untouched. Because `useGlobalPkgs` is off, check that the HM integration follows the system config instead of assuming it does.
- **`autoEnable = false` with an explicit target list.** Stylix's default themes everything it finds, which would also hit KDE/Qt and fight plasma-manager. An explicit list makes the themed set match the spec exactly.
- **Fonts pinned to current values** (`fonts.monospace` = Comic Code, `sizes.terminal = 10`, alacritty held at 7 by `stylix.targets.alacritty.fonts.enable = false`, not by `lib.mkForce`). Stylix's default terminal size of 12 would otherwise change every terminal.
- **Scheme file:** `${pkgs.base16-schemes}/share/themes/tokyo-night-terminal-dark.yaml` plus `stylix.override.base00 = "1a1b26"`. The plain `tokyo-night-dark.yaml` has base08 (red) close to the foreground, so the terminal variant is used for real red/yellow accents, and the override keeps the background `#1A1B26`. Resulting values: base00 `#1A1B26`, base02 `#2F3549`, base08 `#F7768E`, base0A `#E0AF68`, base0C `#7DCFFF`, base0D `#7AA2F7`.
- **Skipped targets:** GTK (Plasma/DMS/nwg-look own and rewrite those files, and the target changes font/icon/cursor, so it would also clobber unmanaged files) and btop (not HM-managed, rewrites its own `btop.conf`).
- **VS Code:** `catppuccin-vsc-icons` stays installed (an icon theme, not a color scheme); only the Catppuccin color extension is swapped for Stylix's. `userSettings` is not set, so `settings.json` stays mutable; select the Stylix color theme once in VS Code.
- **lazygit:** the existing `config.yml` is an empty unmanaged file, so `home.file."${config.xdg.configHome}/lazygit/config.yml".force = true` under the flag.
- **mango and niri colors** are overridden in `features/desktop/stylix.nix` (not in `mangowc.nix`/`niri.nix`): mango `focus_color`/`border_color`/`scratchpad_color` via `lib.mkForce` from base0D/base02/base0C, niri focus-ring active/inactive from base0D/base02 behind an `options ? programs.niri` guard. Hosts without Stylix keep their Catppuccin values.
- **Guard:** an assertion fails if the HM flag is on while the host has no Stylix.

## Risks / Trade-offs

- [Target names differ between Stylix releases] → The first task lists the real target names from the evaluated options before any are referenced.
- [A Stylix target overrides fonts or opacity on top of colors] → Check the evaluated settings for ghostty and alacritty fonts after enabling targets.
- [Stylix's niri target would change cursor, focus-ring and border settings beyond colors] → Set niri's focus-ring colors from `config.lib.stylix.colors`, the same way as mango.
- [Adds a fast-moving input that runs at activation] → Pinned via `flake.lock`, `inputs.nixpkgs.follows = "nixpkgs"`, reviewed on update like the other inputs.

## Migration Plan

Rebuild framework-13. To roll back, run `nixos-rebuild switch --rollback`, or revert the change's commits.

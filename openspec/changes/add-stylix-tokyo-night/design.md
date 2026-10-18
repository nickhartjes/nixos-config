## Context

Theme settings are scattered: ghostty `theme = "Catppuccin Mocha"`, VS Code Catppuccin extensions, a k9s Catppuccin skin, Catppuccin hex values for mango borders (`focus_color = 0x89b4faff` etc.), and a Noctalia Catppuccin preset. Fonts are "ComicCodeLigatures Nerd Font" from `pkgs/fonts-custom`, at size 10 in ghostty and 7 in alacritty. `home-manager.useGlobalPkgs` is off in this repo. Plasma 6 plus plasma-manager is installed on framework-13.

## Goals / Non-Goals

**Goals:** one scheme setting drives every listed surface; no visual change besides colors.

**Non-Goals:** runtime theme switching; theming DMS/Noctalia (they theme themselves, and DMS can follow the wallpaper); Plasma/Qt; fonts; wallpapers.

## Decisions

- **Stylix over hand-rolled base16 templates or per-app Tokyo Night themes.** Stylix already has targets for most surfaces and exposes `config.lib.stylix.colors` for the rest (mango, and niri if it has no target). Per-app themes would recreate today's scattering.
- **NixOS module on framework-13 only**, auto-injected into Home Manager. Other hosts never import Stylix, which keeps servers and VMs untouched. Because `useGlobalPkgs` is off, check that the HM integration follows the system config instead of assuming it does.
- **`autoEnable = false` with an explicit target list.** Stylix's default themes everything it finds, which would also hit KDE/Qt and fight plasma-manager. An explicit list makes the themed set match the spec exactly.
- **Fonts pinned to current values** (`fonts.monospace` = Comic Code, `sizes.terminal = 10`, alacritty force-set to 7). Stylix's default terminal size of 12 would otherwise change every terminal.
- **Scheme file:** `${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml` (base00 `#1A1B26`, base02 `#2F3549`, base0C `#B4F9F8`, base0D `#2AC3DE`).
- **mango colors** come from `config.lib.stylix.colors`, guarded so hosts without Stylix keep their current Catppuccin values.

## Risks / Trade-offs

- [Target names differ between Stylix releases] → The first task lists the real target names from the evaluated options before any are referenced.
- [A Stylix target overrides fonts or opacity on top of colors] → Check the evaluated settings for ghostty and alacritty fonts after enabling targets.
- [Stylix has no niri target] → Set niri's border and focus-ring colors from `config.lib.stylix.colors`, the same way as mango.
- [Adds a fast-moving input that runs at activation] → Pinned via `flake.lock`, `inputs.nixpkgs.follows = "nixpkgs"`, reviewed on update like the other inputs.

## Migration Plan

Rebuild framework-13. To roll back, run `nixos-rebuild switch --rollback`, or revert the change's commits.

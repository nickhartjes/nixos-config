# Stylix Unified Theme (Tokyo Night) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One color scheme, Tokyo Night, applied to terminals, editors, TUIs, GTK and the compositors, replacing the per-app Catppuccin settings.

**Architecture:** Add the Stylix flake input and import its NixOS module on framework-13 only. It auto-injects into Home Manager. Stylix owns colors, not fonts or wallpaper: fonts are pinned to today's values, and wallpaper stays with the wallpapers component and the shells. DMS and Noctalia keep their own theming. Plasma keeps plasma-manager, because Stylix's KDE/Qt targets would fight it.

**Tech Stack:** github:nix-community/stylix, base16 scheme `tokyo-night-dark.yaml` from `pkgs.base16-schemes`.

**Spec:** Omarchy gap analysis, 2026-10-18 session (gap #2 "One theme across all apps"); user chose Tokyo Night.

## Global Constraints

- Scheme: `"${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml"`, polarity `dark`.
- Fonts must not change: monospace `ComicCodeLigatures Nerd Font` (package: `pkgs/fonts-custom`), terminal size `10` (ghostty's current `font-size = 10`). Alacritty is currently 7; record that and set `programs.alacritty.settings.font.size = lib.mkForce 7` rather than let Stylix move it.
- Stylix must not set the wallpaper: `stylix.targets.<wm>` wallpaper handling off (wallpapers component + swaybg/DMS own it).
- Disabled targets: `kde`, `qt` (plasma-manager), and any target for DMS/Noctalia if one exists.
- `home-manager.useGlobalPkgs` is off in this repo: Stylix's HM integration must use `stylix.homeManagerIntegration.followSystem = true` (default) — verify, don't assume.
- Switching themes later = change the one `base16Scheme` line + rebuild. No hotkey switching (out of scope).

## Review Focus

- Font sizes jumping (Stylix default terminal size 12): Task 2 Step 4 asserts ghostty 10 / alacritty 7.
- Plasma session looks broken (Qt/KDE double-themed): Task 2 asserts `stylix.targets.kde.enable == false` and `qt.enable == false`.
- vm-desktop/vm-blackhawk/servers must not pull Stylix: Task 1 asserts `options ? stylix` is false for them.
- mango border colors still hardcoded Catppuccin hex: Task 3 replaces them with `config.lib.stylix.colors`.
- Unknown target names (Stylix renames targets between releases): Task 1 Step 3 lists real target names from the evaluated options before any are referenced.

---

### Task 1: Add Stylix, scheme only

**Files:**
- Modify: `flake.nix` (inputs; framework-13 `modules` list)
- Create: `components/nixos/system/stylix.nix`
- Modify: `components/nixos/system/default.nix` (import)
- Modify: `hosts/framework-13/default.nix` (`components.system.stylix.enable = true;`)

**Interfaces:**
- Produces: `components.system.stylix.enable : bool`; Stylix options (`stylix.*`) on framework-13; `config.lib.stylix.colors` available in nh's HM config.

- [ ] **Step 1: Failing check** — `nix eval .#nixosConfigurations.framework-13.config.stylix.enable` → error: option does not exist.
- [ ] **Step 2: Add input** `stylix = { url = "github:nix-community/stylix"; inputs.nixpkgs.follows = "nixpkgs"; };` and `inputs.stylix.nixosModules.stylix` to framework-13's modules. Run `nix flake lock`.
- [ ] **Step 3: Discover target names** — `nix eval --json .#nixosConfigurations.framework-13.config.home-manager.users.nh.stylix.targets --apply builtins.attrNames` and the same at NixOS level. Record which of: ghostty, alacritty, foot, kitty, wezterm, neovim, vscode, k9s, btop, lazygit, gtk, niri, hyprland, mako, swaylock, kde, qt exist. Later tasks reference only names found here.
- [ ] **Step 4: Component** `stylix.nix`: when enabled set `stylix.enable = true; stylix.base16Scheme = <constraint>; stylix.polarity = "dark"; stylix.fonts.monospace = { package = <fonts-custom>; name = "ComicCodeLigatures Nerd Font"; }; stylix.fonts.sizes.terminal = 10;`, `stylix.autoEnable = false` (targets opt-in in Task 2 — prevents surprise theming of unlisted apps).
- [ ] **Step 5: Verify** — framework-13 `config.stylix.enable` → `true`; `config.lib.stylix.colors.base00` → Tokyo Night background `1a1b26` (compare case-insensitively; the scheme file writes `#1A1B26`); `vm-desktop` `options ? stylix` → false; framework-13 toplevel builds.
- [ ] **Step 6: Commit** `feat(stylix): add Stylix with Tokyo Night scheme (no targets yet)`.

### Task 2: Enable targets, retire per-app Catppuccin

**Files:**
- Modify: `components/home-manager/features/desktop/stylix.nix` (Create) + `features/desktop/default.nix` (import)
- Modify: `components/home-manager/terminal/ghostty.nix:21` (drop `theme = "Catppuccin Mocha"`)
- Modify: `components/home-manager/development/editor/vscode.nix:27-28` (drop catppuccin extensions if Stylix vscode target exists)
- Modify: `components/home-manager/development/infrastructure/k9s.nix:141` (drop catppuccin skin if Stylix k9s target exists)

**Interfaces:**
- Consumes: target names from Task 1 Step 3.
- Produces: `components.features.desktop.stylix.enable : bool` (HM), on for nh via `users/nh/desktop.nix` as `osConfig ? stylix && osConfig.stylix.enable`.

- [ ] **Step 1: Failing check** — `home-manager.users.nh.stylix.targets.ghostty.enable` → `false`.
- [ ] **Step 2: Enable targets** that exist from: ghostty, alacritty, foot, kitty, wezterm, neovim, vscode, k9s, btop, lazygit, gtk. Explicitly `kde.enable = false; qt.enable = false;`.
- [ ] **Step 3: Remove the Catppuccin settings** listed in Files, each only when its Stylix target is enabled (else leave it and note why in the commit body).
- [ ] **Step 4: Verify** — targets above report `true`; `programs.ghostty.settings.font-size` → `10`; `programs.alacritty.settings.font.size` → `7`; `kde`/`qt` → `false`; framework-13 toplevel builds; no `catppuccin` left in ghostty.nix.
- [ ] **Step 5: Commit** `feat(stylix): theme terminals, editors and TUIs with Tokyo Night`.

### Task 3: Compositor colors

**Files:**
- Modify: `components/home-manager/features/desktop/mangowc.nix` (`focus_color`, `border_color`, `scratchpad_color`)
- Modify: `components/home-manager/features/desktop/niri.nix` (focus-ring/border colors, only if Stylix has no niri target from Task 1 Step 3; otherwise enable the target)

**Interfaces:**
- Consumes: `config.lib.stylix.colors` (hex without `#`, keys `base00`..`base0F`).

- [ ] **Step 1: Failing check** — generated `mango/config.conf` contains `focus_color = 0x89b4faff` (Catppuccin blue).
- [ ] **Step 2: mango** — `focus_color = "0x${c.base0D}ff"; border_color = "0x${c.base02}ff"; scratchpad_color = "0x${c.base0C}ff";` where `c = config.lib.stylix.colors`, guarded with `lib.optionalAttrs (config ? lib.stylix)` so hosts without Stylix keep the Catppuccin defaults.
- [ ] **Step 3: niri** — same mapping for active/inactive border and focus ring (base0D active, base02 inactive).
- [ ] **Step 4: Verify** — generated mango config shows `focus_color = 0x2ac3deff` (base0D of `tokyo-night-dark.yaml` is `#2AC3DE`; case may differ); full framework-13 build passes (mango and niri validate their configs at build time); vm-desktop still evaluates.
- [ ] **Step 5: Commit** `feat(stylix): derive mango and niri border colors from the scheme`.
- [ ] **Step 6: Visual check with the user** after rebuild: ghostty, nvim, btop, lazygit, a GTK app (Nautilus/pavucontrol), mango borders, niri borders, Plasma session unchanged.

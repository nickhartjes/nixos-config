## 1. Stylix input and scheme

- [x] 1.1 Add the `stylix` input (`github:nix-community/stylix`, `inputs.nixpkgs.follows = "nixpkgs"`) and `inputs.stylix.nixosModules.stylix` to framework-13's modules, then run `nix flake lock`; verify `config.stylix.enable` exists on framework-13 and `options ? stylix` is false on vm-desktop
- [x] 1.2 List the real target names: `nix eval --json .#nixosConfigurations.framework-13.config.home-manager.users.nh.stylix.targets --apply builtins.attrNames` (and at NixOS level); record which of ghostty, alacritty, foot, kitty, wezterm, neovim, vscode, k9s, btop, lazygit, gtk, niri, kde, qt exist
- [x] 1.3 Create `components/nixos/system/stylix.nix` (`components.system.stylix.enable`) setting `enable`, `autoEnable = false`, `base16Scheme` = tokyo-night-terminal-dark.yaml with `override.base00 = "1a1b26"`, `polarity = "dark"`, Comic Code monospace font, `sizes.terminal = 10`; enable it for framework-13; verify `config.lib.stylix.colors.base00` is `1a1b26` (case-insensitive) and that the HM integration is active for nh even though `useGlobalPkgs` is off

## 2. Application targets

- [x] 2.1 Create `components/home-manager/features/desktop/stylix.nix` enabling the targets ghostty, alacritty, foot, kitty, wezterm, neovim, vscode, k9s, lazygit; set `gtk.enable = false` and `btop.enable = false` (skipped: Plasma/DMS/nwg-look own the GTK files and the target changes non-color settings; btop rewrites its own `btop.conf`); set `kde.enable = false` and `qt.enable = false`; turn it on for nh only when `osConfig ? stylix && osConfig.stylix.enable`; verify each enabled target reports `true` and gtk/btop/kde/qt report `false`; also force the empty lazygit `config.yml` and assert the HM flag requires host Stylix
- [x] 2.2 Remove `theme = "Catppuccin Mocha"` from ghostty.nix, the Catppuccin color extension from vscode.nix (keep `catppuccin-vsc-icons`), and the Catppuccin skin from k9s.nix, each only if its target is enabled; verify a search shows no Catppuccin left for those apps
- [x] 2.3 Hold alacritty's font size with `stylix.targets.alacritty.fonts.enable = false`; verify ghostty `font-size` is 10 and alacritty `font.size` is 7 in the evaluated HM config

## 3. Compositor borders

- [x] 3.1 In `features/desktop/stylix.nix` (mangowc.nix stays unchanged), set mango `focus_color`/`border_color`/`scratchpad_color` with `lib.mkForce` from base0D/base02/base0C of `config.lib.stylix.colors`, so hosts without Stylix keep their current values; verify the generated mango config shows `focus_color = 0x7aa2f7ff` on framework-13 and `0x89b4faff` on vm-desktop (case-insensitive)
- [x] 3.2 For niri, set `programs.niri.settings.layout.focus-ring` active/inactive from base0D/base02 in `features/desktop/stylix.nix` behind an `options ? programs.niri` guard (niri.nix stays unchanged); verify the build validates the niri config
- [x] 3.3 All five nixosConfigurations evaluate and framework-13's toplevel builds

## 3b. DMS theme file

- [x] 3b.1 Generate `~/.config/DankMaterialShell/themes/stylix.json` from `config.lib.stylix.colors` (same mapping as the Stylix DMS target) under the HM Stylix flag, without enabling the `dank-material-shell` target; verify its primary is `#7aa2f7` and background `#1a1b26`, that the path does not exist on disk yet (no clobber), that HM does not manage `DankMaterialShell/settings.json`, and that vm-desktop gets no theme file

## 4. User check

- [ ] 4.1 After rebuild, select the Stylix color theme once in VS Code and the Custom theme `themes/stylix.json` once in DMS, then check visually with the user: ghostty, nvim, lazygit, VS Code, mango borders, niri borders, and an unchanged Plasma session; fonts look the same as before

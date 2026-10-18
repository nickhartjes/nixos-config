## 1. Stylix input and scheme

- [x] 1.1 Add the `stylix` input (`github:nix-community/stylix`, `inputs.nixpkgs.follows = "nixpkgs"`) and `inputs.stylix.nixosModules.stylix` to framework-13's modules, then run `nix flake lock`; verify `config.stylix.enable` exists on framework-13 and `options ? stylix` is false on vm-desktop
- [x] 1.2 List the real target names: `nix eval --json .#nixosConfigurations.framework-13.config.home-manager.users.nh.stylix.targets --apply builtins.attrNames` (and at NixOS level); record which of ghostty, alacritty, foot, kitty, wezterm, neovim, vscode, k9s, btop, lazygit, gtk, niri, kde, qt exist
- [x] 1.3 Create `components/nixos/system/stylix.nix` (`components.system.stylix.enable`) setting `enable`, `autoEnable = false`, `base16Scheme` = tokyo-night-dark.yaml, `polarity = "dark"`, Comic Code monospace font, `sizes.terminal = 10`; enable it for framework-13; verify `config.lib.stylix.colors.base00` is `1a1b26` (case-insensitive) and that the HM integration is active for nh even though `useGlobalPkgs` is off

## 2. Application targets

- [x] 2.1 Create `components/home-manager/features/desktop/stylix.nix` enabling the targets from 1.2 among: ghostty, alacritty, foot, kitty, wezterm, neovim, vscode, k9s, btop, lazygit, gtk; set `kde.enable = false` and `qt.enable = false`; turn it on for nh only when `osConfig ? stylix && osConfig.stylix.enable`; verify each listed target reports `true` and kde/qt report `false`
- [x] 2.2 Remove `theme = "Catppuccin Mocha"` from ghostty.nix, the Catppuccin extensions from vscode.nix, and the Catppuccin skin from k9s.nix, each only if its target is enabled; verify a search shows no Catppuccin left for those apps
- [x] 2.3 Pin alacritty's font size with `lib.mkForce 7`; verify ghostty `font-size` is 10 and alacritty `font.size` is 7 in the evaluated HM config

## 3. Compositor borders

- [x] 3.1 In mangowc.nix, set `focus_color`/`border_color`/`scratchpad_color` from base0D/base02/base0C of `config.lib.stylix.colors`, guarded so hosts without Stylix keep their current values; verify the generated mango config shows `focus_color = 0x2ac3deff` (case-insensitive)
- [x] 3.2 For niri, enable the Stylix target if 1.2 found one; otherwise set active/inactive border and focus ring from base0D/base02; verify the build validates the niri config
- [x] 3.3 All five nixosConfigurations evaluate and framework-13's toplevel builds

## 4. User check

- [ ] 4.1 After rebuild, check visually with the user: ghostty, nvim, btop, lazygit, a GTK app, mango borders, niri borders, and an unchanged Plasma session; fonts look the same as before

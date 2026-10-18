## Purpose

Ensures nh's desktop uses one color scheme consistently across terminals, editors, terminal UIs and compositor window borders, configured in a single place.

## ADDED Requirements

### Requirement: One scheme for all themed surfaces
On framework-13, the terminals (ghostty, alacritty, foot, kitty, wezterm), Neovim, VS Code, k9s, lazygit, and mango and niri window borders SHALL use the Tokyo Night dark palette. A surface SHALL be skipped only if theming it would change more than colors or fight an application that rewrites its own configuration, and the skip SHALL be recorded in the change. GTK applications are skipped (Plasma, DMS and nwg-look own and rewrite the GTK files, and the Stylix GTK target also changes font, icon and cursor settings). btop is skipped (it is not Home Manager managed and rewrites its own `btop.conf`).

#### Scenario: Terminal background
- **WHEN** nh opens ghostty on framework-13
- **THEN** the background color is Tokyo Night's `#1A1B26`

#### Scenario: Focused window border in mango
- **WHEN** a window is focused in mango
- **THEN** its border uses the scheme's accent color (base0D, `#7AA2F7`), not Catppuccin blue `#89B4FA`

### Requirement: Scheme is changed in one place
Changing the color scheme SHALL require editing a single setting and rebuilding; no per-application color settings SHALL remain for themed surfaces.

#### Scenario: No leftover Catppuccin
- **WHEN** the repository is searched after the change
- **THEN** no Catppuccin theme setting is in effect on framework-13 for any surface listed in "One scheme for all themed surfaces" (Catppuccin fallbacks may remain for hosts without Stylix)

### Requirement: Fonts are unchanged
Applying the scheme SHALL NOT change fonts or font sizes: monospace stays "ComicCodeLigatures Nerd Font", with ghostty at size 10 and alacritty at size 7.

#### Scenario: Terminal font size
- **WHEN** nh opens ghostty and alacritty after the change
- **THEN** both show the same font family and size as before

### Requirement: Excluded areas keep their own theming
Plasma (KDE/Qt), the DMS and Noctalia shells, and wallpapers SHALL NOT be themed or changed by this mechanism.

#### Scenario: Plasma session
- **WHEN** nh logs in to Plasma after the change
- **THEN** Plasma's appearance is unchanged

### Requirement: Only framework-13 is affected
Hosts other than framework-13 SHALL NOT gain the theming mechanism, and their evaluated configuration SHALL be unaffected.

#### Scenario: VM evaluation
- **WHEN** vm-desktop is evaluated
- **THEN** it evaluates successfully without the theming options present

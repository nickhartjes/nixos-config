# keybinding-help Specification

## Purpose

Gives the user an on-screen list of the active desktop session's keybindings, opened with one shortcut, so bindings can be looked up without reading configuration files.

## Requirements

### Requirement: One shortcut opens the keybinding reference
In the mango and niri sessions, pressing Super+Shift+/ SHALL show an on-screen list of that session's keybindings; pressing it again or Escape SHALL close it.

#### Scenario: mango session with DMS
- **WHEN** the user presses Super+Shift+/ in a mango session running DMS
- **THEN** a list of mango's keybindings is shown

#### Scenario: niri session
- **WHEN** the user presses Super+Shift+/ in a niri session
- **THEN** niri's hotkey overlay is shown

### Requirement: Existing bindings are preserved
Adding the shortcut SHALL NOT remove or change any existing binding; in particular Super+K remains "focus up" in both compositors.

#### Scenario: Super+K unchanged
- **WHEN** the user presses Super+K after this change
- **THEN** focus moves to the window above, as before

### Requirement: Entries are readable
Every custom binding shown in the niri overlay and in DMS's mango keybind viewer SHALL have a human-readable description rather than a raw command or store path.

#### Scenario: Lock binding in niri
- **WHEN** the niri overlay is open
- **THEN** Mod+Ctrl+L is listed with a description such as "Lock screen"

#### Scenario: Terminal binding in mango
- **WHEN** the DMS keybind viewer is open in a mango session
- **THEN** Super+Return is listed as "Terminal", not as a `/nix/store/...` path

### Requirement: No shortcut without a viewer
When mango runs a shell without a keybinds viewer (Noctalia instead of DMS), Super+Shift+/ SHALL NOT be bound in mango.

#### Scenario: mango with Noctalia
- **WHEN** nh's profile enables mango with Noctalia and without DMS
- **THEN** the generated mango configuration contains no Super+Shift+/ binding

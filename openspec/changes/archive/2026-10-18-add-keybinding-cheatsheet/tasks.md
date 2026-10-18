## 1. mango

- [x] 1.1 Confirm `SUPER+SHIFT,slash` is unbound: `grep -n "SUPER+SHIFT,slash" components/home-manager/features/desktop/mangowc-keybindings.nix` returns nothing
- [x] 1.2 Add `"SUPER+SHIFT,slash,spawn,${dms "keybinds toggle mangowc"}"` to the DMS-only binding list; verify the generated `mango/config.conf` contains it and contains no such line when DMS is disabled
- [x] 1.3 Full framework-13 build succeeds (mango validates the config and its 255-byte line limit)

- [x] 1.4 Give every mango spawn/scratchpad bind a description: binds are `d "<desc>" "<bind>"` pairs in `mangowc-keybindings.nix`, and `mangowc.nix` writes `bind`/`bindl` through `extraConfig` with a `# <desc>` line directly above each described bind (DMS reads the preceding comment; mango would pass an inline `#` to the command); verify the bind lines are identical to the previous config and `dms keybinds show mangowc --path <generated dir>` shows no `/nix/store` descriptions

## 2. niri

- [x] 2.1 Confirm `"Mod+Shift+Slash"` is unbound in `niri-keybindings.nix`, then add `"Mod+Shift+Slash".action.show-hotkey-overlay = [];`; verify `programs.niri.settings.binds."Mod+Shift+Slash"` evaluates
- [x] 2.2 Add `hotkey-overlay.title` to each custom niri bind (Noctalia launcher, session menu, lock, clipboard, emoji, window switcher, control center, terminal, browser); verify no custom bind is left without a title
- [x] 2.3 Full framework-13 build succeeds (niri-flake validates config.kdl); vm-desktop still evaluates

## 3. User check

- [x] 3.1 After rebuild, Super+Shift+/ opens the list in mango and in niri, Escape closes it, and Super+K still focuses up. If DMS shows raw store paths for mango, add descriptions using the syntax in `KeybindsService.qml` and recheck

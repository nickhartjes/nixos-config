## Context

mango runs DMS (`mangowc.enableDMS = true`); niri runs Noctalia, not DMS. DMS 1.7-beta exposes `dms ipc call keybinds toggle <provider>`, and its `KeybindsService` parses `mangowc`, `niri` and `hyprland` configs. Its separate `openBinds`/`toggleBinds` IPC functions are Hyprland-only and must not be used. niri has a built-in `show-hotkey-overlay` action that lists binds carrying `hotkey-overlay.title` plus a built-in "important" set.

## Goals / Non-Goals

**Goals:** one shortcut, both compositors, zero custom code.

**Non-Goals:** Hyprland and Plasma sessions; a cheat sheet that works with Noctalia in mango; editing bindings from the viewer.

## Decisions

- **Super+Shift+/ instead of Omarchy's Super+K.** Super+K is "focus up" in both compositors (vim-style navigation). Shift+/ is "?", which is niri's own default for the overlay, and the key is free in mango.
- **Reuse existing viewers instead of a generated rofi/wofi list.** DMS already parses mango's config, and niri has a native overlay. A generated list would need its own parser for both config formats and would duplicate the descriptions.
- **Titles live next to each niri bind** (`hotkey-overlay.title`) so a description can't drift from its binding.

## Risks / Trade-offs

- [DMS shows raw `spawn,/nix/store/…` commands for mango binds] → Confirmed after the first rebuild. DMS's mango parser (`core/internal/keybinds/providers/mangowc_parser.go`) uses a `# comment` on the line directly above a bind as its description. The HM settings list can't emit comments, so binds are rendered through `extraConfig` (still validated at build time) with descriptions on spawn and scratchpad binds; other actions get DMS's auto-generated labels.
- [A DMS update renames the IPC target] → The binding fails silently; the full build still passes. The runtime check in the tasks catches it.

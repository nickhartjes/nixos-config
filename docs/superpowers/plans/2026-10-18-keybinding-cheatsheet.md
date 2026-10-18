# Keybinding Cheat Sheet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Super+Shift+/ (the "?" key) shows every keybinding of the current session, in both mango and niri.

**Architecture:** No custom tool. DMS ships a keybinds viewer that parses mango's config (`dms ipc call keybinds toggle mangowc`), and niri has a built-in `show-hotkey-overlay` action. Bind both to the same key. Readable descriptions come from each compositor's own annotation mechanism.

**Tech Stack:** DMS keybinds IPC (verified in dms-shell 1.7-beta, `DMSShellIPC.qml`: `toggle(provider)`; `KeybindsService` supports `niri`, `mangowc`, `hyprland`), niri `show-hotkey-overlay` + per-bind `hotkey-overlay.title`.

**Spec:** Omarchy gap analysis, 2026-10-18 session (gap #3 "Keybinding cheat sheet", Omarchy's Super+K).

## Global Constraints

- Key: `SUPER+SHIFT,slash` in mango; `"Mod+Shift+Slash"` in niri. NOT Super+K — it is focus-up in both compositors.
- mango session runs DMS (`mangowc.enableDMS = true`); niri session runs Noctalia, not DMS — so niri uses its native overlay.
- When mango runs Noctalia instead of DMS (`enableNoctalia`), bind nothing (no viewer available); don't fall back to a custom script (YAGNI).

## Review Focus

- DMS viewer shows raw `spawn,/nix/store/...` commands instead of names: Task 1 Step 4 checks readability and, if unreadable, adds the comment-based descriptions DMS reads (verify the format in `KeybindsService.qml` before writing any).
- niri overlay only lists binds with titles or its built-in "important" set: Task 2 gives every custom niri bind in `niri-keybindings.nix` a `hotkey-overlay.title`.
- Key conflict: Super+Shift+/ already bound — Task 1/2 Step 1 grep proves it's free.

---

### Task 1: mango → DMS keybinds viewer

**Files:**
- Modify: `components/home-manager/features/desktop/mangowc-keybindings.nix` (DMS block, near the other `${dms ...}` binds ~line 37-43)

- [ ] **Step 1: Check the key is free** — `grep -n "SUPER+SHIFT,slash" components/home-manager/features/desktop/mangowc-keybindings.nix` → no match.
- [ ] **Step 2: Add** `"SUPER+SHIFT,slash,spawn,${dms "keybinds toggle mangowc"}"` to the DMS-only list.
- [ ] **Step 3: Verify build** — full framework-13 build passes (mango validates config; 255-byte line limit — this line is ~110 bytes).
- [ ] **Step 4: Runtime check with the user** — in a mango session press Super+Shift+/: DMS modal lists binds. If entries show raw store paths, read `KeybindsService.qml`'s mango parser for its description syntax and add descriptions for the launcher, terminal, lock, screenshot and window-management binds.
- [ ] **Step 5: Commit** `feat(mango): Super+Shift+/ opens the DMS keybinds cheat sheet`.

### Task 2: niri → native hotkey overlay

**Files:**
- Modify: `components/home-manager/features/desktop/niri-keybindings.nix`

- [ ] **Step 1: Check the key is free** — `grep -n '"Mod+Shift+Slash"' components/home-manager/features/desktop/niri-keybindings.nix` → no match.
- [ ] **Step 2: Add** `"Mod+Shift+Slash".action.show-hotkey-overlay = [];` to the always-on bindings.
- [ ] **Step 3: Titles** — add `hotkey-overlay.title = "<Verb phrase>";` to each custom bind (Noctalia launcher, session menu, lock, clipboard, emoji, window switcher, control center, terminal, browser), e.g. `"Mod+Ctrl+L" = { action.spawn = ...; hotkey-overlay.title = "Lock screen"; };`.
- [ ] **Step 4: Verify** — full framework-13 build passes (niri-flake validates config.kdl); `programs.niri.settings.binds."Mod+Shift+Slash"` evaluates.
- [ ] **Step 5: Runtime check with the user** — Super+Shift+/ in niri shows the overlay with the titled entries.
- [ ] **Step 6: Commit** `feat(niri): Super+Shift+/ shows the hotkey overlay with titled binds`.

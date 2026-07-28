# Enable KDE Plasma on framework-13 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace COSMIC with KDE Plasma 6 as the desktop environment on the framework-13 host, with SDDM (Wayland greeter) as the display manager.

**Architecture:** This is a NixOS flake repo where desktop environments and display managers are toggled through custom `components.desktop.*` / `components.display.*` option flags. The Plasma module and the home-manager plasma-manager config already exist; the work is flipping host-level flags on framework-13 and adding a small Wayland default to the SDDM module.

**Tech Stack:** Nix flakes, NixOS modules. No conventional test suite — verification is `nix eval` on the flake's NixOS configuration plus a full system build.

**Spec:** `docs/superpowers/specs/2026-07-28-enable-plasma-framework-13-design.md`

## Global Constraints

- Only files named in the tasks may change: `components/nixos/display-manager/sddm.nix` and `hosts/framework-13/default.nix`.
- Do NOT touch `components/nixos/desktop-manager/plasma.nix`, `users/nh/desktop.nix`, or any other host.
- The repo working tree has unrelated uncommitted changes (`flake.lock`, `users/nh.nix`, staged `secrets/framework-13/hevy-api-key.age`, etc.). **Never** use `git add -A`, `git add .`, or bare `git commit -a`. Stage only the exact file(s) named in each commit step.
- Repo style: nix files are formatted with alejandra-style formatting (2-space indent, `{lib, ...}:` argument sets broken one-per-line when multiline).
- All `nix eval` / build commands run from the repo root `/home/nh/.config/nixos-config`.

---

### Task 1: SDDM module — default to Wayland greeter

**Files:**
- Modify: `components/nixos/display-manager/sddm.nix`

**Interfaces:**
- Consumes: `components.display.sddm.enable` option (already declared in this file); central force-wiring in `components/nixos/display-manager/default.nix` (`services.displayManager.sddm.enable = lib.mkForce cfg.sddm.enable;`) — do not duplicate the service enable here.
- Produces: when `components.display.sddm.enable = true`, the built system has `services.displayManager.sddm.wayland.enable = true` (overridable per host because of `mkDefault`). Task 2 relies on this.

- [ ] **Step 1: Capture the failing check**

No host currently enables SDDM, so assert the current wayland default on framework-13 evaluates to `false`:

Run:
```bash
nix eval .#nixosConfigurations.framework-13.config.services.displayManager.sddm.wayland.enable
```
Expected: `false`

(This is the "failing test" baseline. It will only flip to `true` after BOTH tasks are done; Task 1 alone keeps it `false` because the flag is still off. The real check for Task 1 is that evaluation still succeeds after the edit — Step 3.)

- [ ] **Step 2: Rewrite the module**

Replace the entire contents of `components/nixos/display-manager/sddm.nix` (currently just the option declaration) with:

```nix
{
  config,
  lib,
  ...
}: {
  options.components.display.sddm = {
    enable = lib.mkEnableOption "SDDM display manager";
  };

  config = lib.mkIf config.components.display.sddm.enable {
    # Run the SDDM greeter on Wayland instead of spawning an X server.
    # mkDefault so a host can override back to X11 if needed.
    services.displayManager.sddm.wayland.enable = lib.mkDefault true;
  };
}
```

- [ ] **Step 3: Verify the flake still evaluates**

Run:
```bash
nix eval .#nixosConfigurations.framework-13.config.services.displayManager.sddm.wayland.enable
```
Expected: `false` (flag still off on this host — but the command must succeed, proving the module change introduces no eval error).

- [ ] **Step 4: Commit**

```bash
git add components/nixos/display-manager/sddm.nix
git commit -m "feat(display): default SDDM greeter to Wayland when enabled"
```

---

### Task 2: framework-13 — swap COSMIC for Plasma, cosmic-greeter for SDDM

**Files:**
- Modify: `hosts/framework-13/default.nix`

**Interfaces:**
- Consumes: `components.desktop.plasma.enable` (from `components/nixos/desktop-manager/plasma.nix`), `components.display.sddm.enable` + Wayland default from Task 1.
- Produces: the final framework-13 system configuration. Nothing downstream.

- [ ] **Step 1: Capture the failing checks (current state)**

Run:
```bash
nix eval .#nixosConfigurations.framework-13.config.services.desktopManager.plasma6.enable
nix eval .#nixosConfigurations.framework-13.config.services.displayManager.defaultSession
```
Expected: `false` and `"cosmic"` respectively.

- [ ] **Step 2: Edit the host file**

In `hosts/framework-13/default.nix`, make exactly these five changes:

1. In the `components.desktop` block: `cosmic.enable = true;` → `cosmic.enable = false;`
2. In the `components.desktop` block: `plasma.enable = false;` → `plasma.enable = true;`
3. In the `components.display` block: `cosmic-greeter.enable = true;` → `cosmic-greeter.enable = false;`
4. In the `components.display` block: `sddm.enable = false;` → `sddm.enable = true;`
5. Near the top of the module body: `services.displayManager.defaultSession = lib.mkForce "cosmic";` → `services.displayManager.defaultSession = lib.mkForce "plasma";`

Leave `mangowc.enable = true;` and `niri.enable = true;` untouched (they are WMs, allowed alongside a full DE). Leave every other line in the file untouched, including the comment above the defaultSession line.

- [ ] **Step 3: Verify the configuration evaluates to the target state**

Run:
```bash
nix eval .#nixosConfigurations.framework-13.config.services.desktopManager.plasma6.enable
nix eval .#nixosConfigurations.framework-13.config.services.displayManager.sddm.enable
nix eval .#nixosConfigurations.framework-13.config.services.displayManager.sddm.wayland.enable
nix eval .#nixosConfigurations.framework-13.config.services.displayManager.defaultSession
nix eval .#nixosConfigurations.framework-13.config.services.displayManager.cosmic-greeter.enable
nix eval .#nixosConfigurations.framework-13.config.services.greetd.enable
```
Expected, in order: `true`, `true`, `true`, `"plasma"`, `false`, `false`.

Successful evaluation also proves the one-DE and one-DM assertions pass (assertions abort eval of `system.build.toplevel`, and are checked at build in Step 4).

- [ ] **Step 4: Full system build**

Run:
```bash
nix build .#nixosConfigurations.framework-13.config.system.build.toplevel -o /tmp/claude-1001/-home-nh--config-nixos-config/24df0a9e-b040-4aca-a1de-c9488f623506/scratchpad/plasma-build-result
```
Expected: exits 0. (May take a while — Plasma 6 closure. Do not write the `result` symlink into the repo root; it already has an untracked `result` from earlier work.)

- [ ] **Step 5: Commit**

```bash
git add hosts/framework-13/default.nix
git commit -m "feat(framework-13): replace COSMIC with Plasma 6 + SDDM"
```

---

## Post-plan (manual, user-performed)

Not part of automated execution: `sudo nixos-rebuild switch --flake .#framework-13` (or `nh os switch`), reboot, confirm SDDM appears with Plasma (Wayland) as default session and plasma-manager shortcuts work (Meta+1..4, Meta+Return → ghostty).

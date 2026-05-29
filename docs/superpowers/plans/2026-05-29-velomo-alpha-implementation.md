# velomo-alpha Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new NixOS host `velomo-alpha` to this flake. The host boots into Docker + Komodo (Core + Periphery + MongoDB) and acts as a GitOps deployer for compose-based workloads stored in a private git repo.

**Architecture:** Three-layer split. NixOS provides the base OS (single-disk ext4, systemd-boot, DHCP, Tailscale, SSH key-only) and bootstraps three Komodo containers via `virtualisation.oci-containers`. Komodo then manages all other workloads from a private compose repo via its Resource Sync feature. Workstation-flavored `users/nh.nix` is **not** reused on this server; the `nh` user is defined inline.

**Tech Stack:** NixOS (unstable channel), Nix flakes, disko, agenix, home-manager NixOS module (available but unused), `virtualisation.oci-containers` (Docker backend), Tailscale, Komodo (`ghcr.io/moghtech/komodo-core`, `ghcr.io/moghtech/komodo-periphery`), MongoDB.

**Spec:** [docs/superpowers/specs/2026-05-29-velomo-alpha-server-design.md](../specs/2026-05-29-velomo-alpha-server-design.md)

**Two-part execution:**
- **Part A — Repo work** (Tasks 1-8): Performed on `framework-13` in this nixos-config repo. Each task ends with a `nix flake check` and/or `nix build --dry-run` verification. Fully agent-executable.
- **Part B — On-target runbook** (Tasks 9-13): Performed by a human on the bare-metal `velomo-alpha` hardware. Each task is a checklist with exact commands; cannot be done by an agent without hardware access.

---

## File Structure

**New files under `hosts/velomo-alpha/`:**

| File | Responsibility |
|---|---|
| `default.nix` | Entry point — imports configuration + components/nixos directly (skipping `hosts/common/`). Sets component toggles. Conditionally imports `secrets.nix` and `services/` once they're populated (commented out in Phase 0). |
| `configuration.nix` | Hostname, locale, time zone, NetworkManager + DHCP, OpenSSH (key-only), inline `nh` user, Tailscale enable (autoconnect disabled until secrets exist), nixpkgs/nix-settings copied minimally from `hosts/common/`, `stateVersion`. |
| `disko-config.nix` | Single disk → GPT + 1 MB BIOS-boot stub + 512 MB ESP (vfat) + remainder ext4 on `/`. Device path placeholder `/dev/nvme0n1`. |
| `hardware-configuration.nix` | Empty placeholder. Overwritten on target by `nixos-generate-config`. |
| `secrets.nix` | Empty `{ ... }: { }` placeholder until Phase 2. |
| `services/default.nix` | Imports `./komodo.nix`. |
| `services/komodo.nix` | Three `virtualisation.oci-containers` entries (mongo, komodo-core, komodo-periphery), state directory creation, Docker network setup, env-from-file wiring for agenix secrets. |

**Files modified:**

| File | Change |
|---|---|
| `flake.nix` | Add `velomo-alpha` entry under `nixosConfigurations` with `disko` + `agenix` modules. |

**Files created later (Phase 2, manually on framework-13):**

| File | Purpose |
|---|---|
| `secrets/secrets.nix` | Add `velomo-alpha` system SSH host key entry; add per-secret `publicKeys` for the new secrets. |
| `secrets/velomo-alpha/komodo-passkey.age` | Shared Core↔Periphery passkey. |
| `secrets/velomo-alpha/komodo-jwt.age` | JWT signing key for Core. |
| `secrets/velomo-alpha/komodo-db.env.age` | `MONGO_INITDB_ROOT_USERNAME` + `MONGO_INITDB_ROOT_PASSWORD` in env-file format. |
| `secrets/velomo-alpha/tailscale-authkey.age` | Tailscale machine auth key. |

---

# Part A — Repo Work (on framework-13)

## Task 1: Create the host directory with skeleton files

**Files:**
- Create: `hosts/velomo-alpha/hardware-configuration.nix`
- Create: `hosts/velomo-alpha/secrets.nix`
- Create: `hosts/velomo-alpha/services/default.nix`

- [ ] **Step 1: Create the directory**

Run: `mkdir -p hosts/velomo-alpha/services`

- [ ] **Step 2: Write placeholder hardware-configuration.nix**

File: `hosts/velomo-alpha/hardware-configuration.nix`

```nix
# Placeholder. Replaced on target by `nixos-generate-config --no-filesystems`.
# Do not edit by hand once generated.
{ ... }: { }
```

- [ ] **Step 3: Write placeholder secrets.nix**

File: `hosts/velomo-alpha/secrets.nix`

```nix
# Populated in Phase 2 (see plan). Empty until secrets are created and
# the host's SSH key is added to secrets/secrets.nix.
{ ... }: { }
```

- [ ] **Step 4: Write services/default.nix**

File: `hosts/velomo-alpha/services/default.nix`

```nix
{
  imports = [
    ./komodo.nix
  ];
}
```

- [ ] **Step 5: Commit the skeleton**

```bash
git add hosts/velomo-alpha/
git commit -m "feat(velomo-alpha): skeleton host directory"
```

---

## Task 2: Write the disko configuration

**Files:**
- Create: `hosts/velomo-alpha/disko-config.nix`

Mirrors `hosts/vm-blackhawk/disko-config.nix` but assumes NVMe. The device path is the most likely thing to change at install time — see Task 9.

- [ ] **Step 1: Write disko-config.nix**

File: `hosts/velomo-alpha/disko-config.nix`

```nix
{
  disko.devices = {
    disk = {
      nixos = {
        type = "disk";
        # IMPORTANT: confirm this device path on the target machine before
        # running disko. On NVMe systems it is usually /dev/nvme0n1; on
        # SATA/SCSI systems it is /dev/sda. `lsblk` on the installer ISO
        # shows the right path.
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
```

- [ ] **Step 2: Commit**

```bash
git add hosts/velomo-alpha/disko-config.nix
git commit -m "feat(velomo-alpha): disko config (single-disk ext4, NVMe default)"
```

---

## Task 3: Write configuration.nix

**Files:**
- Create: `hosts/velomo-alpha/configuration.nix`

This file holds everything that would normally come from `hosts/common/default.nix` (minus the workstation user tree) plus the host-specific networking, SSH, and inline `nh` user.

- [ ] **Step 1: Write configuration.nix**

File: `hosts/velomo-alpha/configuration.nix`

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: {
  # ---- Bootloader ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- Nixpkgs (from common, minus what we don't need) ----
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  # ---- Nix daemon (from common) ----
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = ["root"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (flakeName: _: "${flakeName}=flake:${flakeName}") flakeInputs;
  };

  # ---- Identity ----
  networking.hostName = "velomo-alpha";
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- Networking ----
  networking.networkmanager.enable = true;

  # ---- Tailscale (autoconnect added in Phase 2 once auth-key secret exists) ----
  services.tailscale.enable = true;

  # ---- SSH ----
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # ---- User: inline nh definition (see spec: Server-vs-Workstation User Split) ----
  # NOTE: do NOT import users/nh.nix here. The workstation tree assumes
  # framework-13 keys and a full home-manager profile.
  users.users.nh = {
    isNormalUser = true;
    description = "nh";
    home = "/home/nh";
    # Allow first-time console login if SSH key access fails; remove later if desired.
    initialHashedPassword = "$y$j9T$SWeufZ9NrHX0.d.w72nc20$1zKkVcJHZfIvS5VMqhdP5RwQ7wQHzbsIi.ArDYRXDK7";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      # framework-13 SSH key — copied verbatim from users/nh.nix
      "sh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8Fzq/ktI9g9FYsADc8NkaYDhHuXIPPPxwRjXT7Gcwk info@nickhartjes.nl"
    ];
    shell = pkgs.bash;
  };

  # ---- Minimal system packages ----
  environment.systemPackages = with pkgs; [
    git
    neovim
    htop
  ];

  # ---- Firewall ----
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedTCPPorts = [22];
    interfaces.tailscale0.allowedTCPPorts = [9120];
  };

  # ---- stateVersion: pin to the release the host was first installed against ----
  system.stateVersion = "25.05";
}
```

- [ ] **Step 2: Verify the file parses with `nix-instantiate --parse`**

Run: `nix-instantiate --parse hosts/velomo-alpha/configuration.nix > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add hosts/velomo-alpha/configuration.nix
git commit -m "feat(velomo-alpha): base configuration (inline nh user, no workstation tree)"
```

---

## Task 4: Write the Komodo service module

**Files:**
- Create: `hosts/velomo-alpha/services/komodo.nix`

Defines the three Komodo containers as `virtualisation.oci-containers` entries on a dedicated `komodo` Docker network. State lives under `/var/lib/komodo/`. Env files come from agenix secrets — the secrets don't exist yet (created in Phase 2), so this file references them via `config.age.secrets.<name>.path`. Importing this file before the secrets exist will fail evaluation, which is why `default.nix` doesn't import `services/` until Task 7.

- [ ] **Step 1: Write services/komodo.nix**

File: `hosts/velomo-alpha/services/komodo.nix`

```nix
{
  config,
  pkgs,
  lib,
  ...
}: let
  komodoDataRoot = "/var/lib/komodo";
  # Image tags pinned to a major version. Verify the current stable major
  # at https://github.com/moghtech/komodo/pkgs/container/komodo-core before
  # promoting velomo-alpha to "in use".
  komodoImageTag = "1";
in {
  # ---- State directories ----
  systemd.tmpfiles.rules = [
    "d ${komodoDataRoot} 0750 root root - -"
    "d ${komodoDataRoot}/mongo 0750 root root - -"
    "d ${komodoDataRoot}/core 0750 root root - -"
    "d ${komodoDataRoot}/periphery 0750 root root - -"
    "d /opt/stacks 0755 root root - -"
  ];

  # ---- Dedicated docker network so the three containers can resolve each
  #      other by name without exposing extra host ports ----
  systemd.services.init-komodo-network = {
    description = "Create internal komodo docker network";
    after = ["docker.service"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker network inspect komodo >/dev/null 2>&1 \
        || ${pkgs.docker}/bin/docker network create komodo
    '';
  };

  # ---- Containers ----
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      mongo = {
        image = "mongo:7";
        autoStart = true;
        extraOptions = ["--network=komodo"];
        environmentFiles = [
          config.age.secrets."velomo-alpha/komodo-db".path
        ];
        volumes = [
          "${komodoDataRoot}/mongo:/data/db"
        ];
      };

      komodo-core = {
        image = "ghcr.io/moghtech/komodo-core:${komodoImageTag}";
        autoStart = true;
        dependsOn = ["mongo"];
        extraOptions = ["--network=komodo" "--init"];
        ports = ["9120:9120"];
        environment = {
          KOMODO_HOST = "http://velomo-alpha:9120";
          KOMODO_DATABASE_ADDRESS = "mongo:27017";
          KOMODO_FIRST_SERVER = "http://komodo-periphery:8120";
        };
        environmentFiles = [
          config.age.secrets."velomo-alpha/komodo-db".path
          # Single env file that exports KOMODO_DATABASE_USERNAME,
          # KOMODO_DATABASE_PASSWORD, KOMODO_PASSKEY, KOMODO_JWT_SECRET.
          # Compose them into one secret file at edit time.
          config.age.secrets."velomo-alpha/komodo-core-env".path
        ];
        volumes = [
          "${komodoDataRoot}/core:/config"
        ];
      };

      komodo-periphery = {
        image = "ghcr.io/moghtech/komodo-periphery:${komodoImageTag}";
        autoStart = true;
        extraOptions = ["--network=komodo" "--init"];
        ports = ["127.0.0.1:8120:8120"];
        environment = {
          KOMODO_PORT = "8120";
        };
        environmentFiles = [
          config.age.secrets."velomo-alpha/komodo-passkey-env".path
        ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "${komodoDataRoot}/periphery:/etc/komodo"
          "/opt/stacks:/opt/stacks"
        ];
      };
    };
  };

  # ---- Ensure containers wait for the komodo network to exist ----
  systemd.services.docker-mongo.after = ["init-komodo-network.service"];
  systemd.services.docker-mongo.requires = ["init-komodo-network.service"];
  systemd.services.docker-komodo-core.after = ["init-komodo-network.service"];
  systemd.services.docker-komodo-core.requires = ["init-komodo-network.service"];
  systemd.services.docker-komodo-periphery.after = ["init-komodo-network.service"];
  systemd.services.docker-komodo-periphery.requires = ["init-komodo-network.service"];
}
```

Note on secret layout: this file references three logical env files:
- `velomo-alpha/komodo-db` — mongo root user + password (consumed by both `mongo` and `komodo-core` so they agree on credentials)
- `velomo-alpha/komodo-core-env` — `KOMODO_PASSKEY`, `KOMODO_JWT_SECRET` (plus `KOMODO_DATABASE_USERNAME` and `KOMODO_DATABASE_PASSWORD` mirroring `komodo-db`)
- `velomo-alpha/komodo-passkey-env` — just `KOMODO_PASSKEY` for periphery

This is one more file than the spec listed but cleaner in practice — env-file separation matches consumer separation. The spec's `komodo-passkey.age` / `komodo-jwt.age` / `komodo-db.age` get reshaped to these three env files in Task 11.

- [ ] **Step 2: Verify the file parses**

Run: `nix-instantiate --parse hosts/velomo-alpha/services/komodo.nix > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add hosts/velomo-alpha/services/komodo.nix
git commit -m "feat(velomo-alpha): komodo oci-containers module"
```

---

## Task 5: Write default.nix (Phase 0 imports only)

**Files:**
- Create: `hosts/velomo-alpha/default.nix`

Only imports what's needed for first boot: hardware, disko, configuration, and the `components/nixos` tree (opt-in modules — none of them activate by default). `secrets.nix` and `services/` are commented out until Phase 2/3.

- [ ] **Step 1: Write default.nix**

File: `hosts/velomo-alpha/default.nix`

```nix
{
  pkgs,
  lib,
  inputs,
  outputs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./configuration.nix
    ../../components/nixos
    inputs.home-manager.nixosModules.home-manager

    # Imported in Phase 2 once agenix secrets exist:
    # ./secrets.nix

    # Imported in Phase 3 once docker + secrets are ready:
    # ./services
  ];

  # home-manager wiring kept available even though no user-level HM modules are loaded.
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs outputs;};
  };

  # Phase 3 enables this:
  # components.virtualization.docker.enable = true;
}
```

- [ ] **Step 2: Verify the file parses**

Run: `nix-instantiate --parse hosts/velomo-alpha/default.nix > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add hosts/velomo-alpha/default.nix
git commit -m "feat(velomo-alpha): default.nix (Phase 0 minimal imports)"
```

---

## Task 6: Wire velomo-alpha into the flake

**Files:**
- Modify: `flake.nix`

Add a `velomo-alpha` entry to `nixosConfigurations` following the existing pattern. Include `disko` and `agenix` modules from day one — the latter is harmless until secrets are declared.

- [ ] **Step 1: Locate the nixosConfigurations block**

Run: `grep -n "nixosConfigurations = {" flake.nix`
Expected: a single line number where the block opens. The block also contains existing entries for `vm-blackhawk`, `vm-desktop`, `framework-13`, and `m3-hermes-hetzner`.

- [ ] **Step 2: Edit flake.nix — add the velomo-alpha entry inside the `nixosConfigurations = { ... };` block**

Insert this entry alongside the existing `vm-blackhawk`, `vm-desktop`, `framework-13`, and `m3-hermes-hetzner` entries:

```nix
      # Minimal Komodo server (bare-metal homelab). See spec:
      # docs/superpowers/specs/2026-05-29-velomo-alpha-server-design.md
      velomo-alpha = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/velomo-alpha
          inputs.disko.nixosModules.disko
          agenix.nixosModules.default
        ];
      };
```

- [ ] **Step 3: Verify the flake evaluates**

Run: `nix flake show --no-write-lock-file 2>&1 | grep velomo-alpha`
Expected: a line showing `velomo-alpha: NixOS configuration` (or similar).

- [ ] **Step 4: Verify the full configuration evaluates**

Run: `nix eval .#nixosConfigurations.velomo-alpha.config.networking.hostName --no-write-lock-file`
Expected: `"velomo-alpha"`

- [ ] **Step 5: Verify the system can be built (dry-run, no GC roots)**

Run: `nix build .#nixosConfigurations.velomo-alpha.config.system.build.toplevel --no-link --dry-run --no-write-lock-file 2>&1 | tail -5`
Expected: lines describing what would be built, no errors. If there are errors, fix them before proceeding. Common causes: typos in `configuration.nix`, missing options.

- [ ] **Step 6: Commit**

```bash
git add flake.nix
git commit -m "feat(velomo-alpha): wire host into flake.nix"
```

---

## Task 7: Smoke-test the whole flake

**Files:** none (verification only)

- [ ] **Step 1: Run `nix flake check`**

Run: `nix flake check --no-write-lock-file --no-build 2>&1 | tail -10`
Expected: no errors mentioning `velomo-alpha`. Warnings from other hosts are acceptable.

- [ ] **Step 2: Run `nixos-rebuild dry-build` against velomo-alpha from framework-13**

This catches build-time errors (e.g., bad option values) that pure evaluation misses.

Run: `sudo nixos-rebuild dry-build --flake .#velomo-alpha 2>&1 | tail -20`
Expected: builds the toplevel derivation symbolically and prints what would change; no errors.

If errors mention missing `/etc/ssh/ssh_host_*` or `hardware-configuration.nix` being empty, that's expected — those are filled in on the target. Errors about Nix syntax, option types, or undefined attributes need to be fixed before Phase 1.

- [ ] **Step 3: No commit needed** (verification step)

---

## Task 8: Document the Phase 0 completion state

**Files:**
- Modify: `hosts/velomo-alpha/default.nix` (add a comment header)

- [ ] **Step 1: Add a comment header to `hosts/velomo-alpha/default.nix`**

Edit `hosts/velomo-alpha/default.nix`. Add at the very top of the file, before the `{` opening:

```nix
# velomo-alpha — minimal Komodo server. See:
#   docs/superpowers/specs/2026-05-29-velomo-alpha-server-design.md
#   docs/superpowers/plans/2026-05-29-velomo-alpha-implementation.md
#
# State: Phase 0 (repo skeleton). Secrets and services are not yet imported.
# To advance, follow the Phase 1+ runbook in the plan above.
```

- [ ] **Step 2: Commit and push**

```bash
git add hosts/velomo-alpha/default.nix
git commit -m "docs(velomo-alpha): cross-reference spec/plan from default.nix"
git push
```

**Part A complete.** `velomo-alpha` is a defined-but-uninstalled NixOS configuration. `nix flake check` passes. Ready for the on-target runbook (Part B).

---

# Part B — On-Target Runbook (manual)

These tasks require physical or virtual access to the `velomo-alpha` hardware. Each task is a checklist; commands assume you're running on the target unless noted otherwise.

## Task 9: Install with nixos-anywhere (primary path)

**Where:** framework-13 → velomo-alpha (over SSH)

[`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) installs NixOS on the target machine over SSH from framework-13. It kexecs into a NixOS installer, runs disko, installs the flake config, and reboots — no keyboard/monitor on velomo-alpha needed.

- [ ] **Step 1: Boot the target into something SSH-reachable**

Two options, pick one:
- **Official NixOS installer ISO** (recommended): write a recent unstable or 25.05 minimal ISO to a USB stick, boot velomo-alpha from it. The installer auto-enables SSH on the root user with **no password** (you can log in as `root@<ip>` with the host's `~/.ssh/authorized_keys` if pre-populated, or set a password via `passwd` on the console).
- **Any other Linux live USB** (Ubuntu/Debian/whatever) with SSH enabled. nixos-anywhere will kexec into NixOS and replace it.

- [ ] **Step 2: Find velomo-alpha's IP**

On velomo-alpha's console: `ip a` and note the wired interface address. Or check your router's DHCP leases.

- [ ] **Step 3: (Optional) Set a root password on the installer**

If you didn't add framework-13's SSH key to the installer ahead of time, on the velomo-alpha console run:

```bash
sudo passwd root
```

Set a temporary password. nixos-anywhere will prompt for it once.

- [ ] **Step 4: Confirm install disk path on the target**

On velomo-alpha's console: `lsblk`. Confirm the target install disk path. If it's NOT `/dev/nvme0n1`, edit `hosts/velomo-alpha/disko-config.nix` on framework-13 to match (e.g. `/dev/sda`), commit, and proceed.

- [ ] **Step 5: Run nixos-anywhere from framework-13**

From the nixos-config repo on framework-13:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#velomo-alpha \
  --generate-hardware-config nixos-generate-config \
  ./hosts/velomo-alpha/hardware-configuration.nix \
  root@<velomo-alpha-ip>
```

What this does:
- Connects to `root@<velomo-alpha-ip>` over SSH.
- kexecs into a NixOS installer environment (if not already on NixOS installer).
- Runs `nixos-generate-config --no-filesystems` on the target and writes the result back to `./hosts/velomo-alpha/hardware-configuration.nix` on framework-13.
- Runs disko using `./hosts/velomo-alpha/disko-config.nix`. **This erases the disk.**
- Builds the velomo-alpha system closure on framework-13 (or the target — nixos-anywhere chooses based on resources).
- Copies it to the target and runs `nixos-install`.
- Reboots the target.

Expected duration: 5-20 minutes depending on network speed and how much of the closure has to be built.

- [ ] **Step 6: Commit the generated hardware-configuration.nix**

After nixos-anywhere succeeds, the placeholder `hardware-configuration.nix` on framework-13 has been overwritten with the real one generated on the target.

```bash
git add hosts/velomo-alpha/hardware-configuration.nix
git commit -m "feat(velomo-alpha): real hardware-configuration.nix (from target)"
git push
```

- [ ] **Step 7: Verify the target rebooted into NixOS**

After the target reboots, SSH in as `nh` (the user defined in `configuration.nix` — framework-13's SSH key is already in its authorized_keys):

```bash
ssh nh@<velomo-alpha-ip>
hostname
# Expected: velomo-alpha
nixos-version
# Expected: a 25.05 or 26.05.* version string
```

---

### Fallback: manual ISO install

If `nixos-anywhere` doesn't work (e.g. too little RAM on the target to kexec, network firewall blocking SSH from framework-13, or you prefer the manual path), use these steps from the target console instead:

- Boot the NixOS installer ISO on velomo-alpha.
- Confirm Ethernet has DHCP'd: `ip a`.
- Confirm install disk path: `lsblk`.
- Clone the repo: `nix-shell -p git --run "git clone <REPO_URL> /tmp/nixos-config"` and `cd /tmp/nixos-config`.
- Generate real hardware-config: `sudo nixos-generate-config --no-filesystems --dir /tmp/hw && sudo cp /tmp/hw/hardware-configuration.nix hosts/velomo-alpha/hardware-configuration.nix`.
- Run disko: `sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko hosts/velomo-alpha/disko-config.nix` (⚠️ this erases the disk).
- Run install: `sudo nixos-install --flake .#velomo-alpha --no-root-passwd`.
- `sudo reboot`.
- On framework-13, after the install: `scp` the real `hardware-configuration.nix` back from the target and commit it.

---

## Task 10: First SSH and host-key extraction

**Where:** framework-13 (your laptop) → velomo-alpha (the new server)

- [ ] **Step 1: Find velomo-alpha on the LAN**

Either look up its DHCP lease on your router, or run `tailscale status` (no, Tailscale isn't up yet on the new host), or just try `ssh nh@velomo-alpha.local` if mDNS works.

- [ ] **Step 2: SSH in as `nh`**

```bash
ssh nh@<velomo-alpha-ip>
```

Expected: logged in. The framework-13 SSH key is already in `authorizedKeys` via the inline user, so no password is needed.

- [ ] **Step 3: Read the new host's SSH ed25519 public key**

On velomo-alpha:

```bash
cat /etc/ssh/ssh_host_ed25519_key.pub
```

Copy the entire line (starts with `ssh-ed25519`). You'll paste it into `secrets/secrets.nix` in the next task.

- [ ] **Step 4: Log out**

```bash
exit
```

---

## Task 11: Create agenix secrets

**Where:** framework-13, in the nixos-config repo

- [ ] **Step 1: Edit `secrets/secrets.nix` to register the new host**

Open `secrets/secrets.nix`. The current content looks like:

```nix
let
  framework-13 = "ssh-ed25519 AAAA...";
  framework-13-2 = "ssh-ed25519 AAAA...";
  systems = [framework-13];
in {
  "secret1.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  ...
}
```

Add a `velomo-alpha` line in the `let` block (paste the host key you copied), then add per-secret entries for the new Komodo secrets:

```nix
let
  framework-13 = "ssh-ed25519 AAAA... nick@hartj.es";
  framework-13-2 = "ssh-ed25519 AAAA... nick@hartj.es";
  velomo-alpha = "ssh-ed25519 AAAA<PASTE THE KEY YOU READ IN TASK 10>";
  systems = [framework-13];
  velomoSystems = [velomo-alpha];
in {
  "secret1.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  # (existing nh/* entries unchanged)
  "nh/ssh-framework-13.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  # ...

  # New velomo-alpha secrets:
  "velomo-alpha/komodo-passkey-env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/komodo-core-env.age".publicKeys   = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/komodo-db.age".publicKeys         = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/tailscale-authkey.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
}
```

- [ ] **Step 2: Create the secrets directory**

```bash
mkdir -p secrets/velomo-alpha
```

- [ ] **Step 3: Create the Komodo db env file**

```bash
cd secrets
nix run github:ryantm/agenix -- -e velomo-alpha/komodo-db.age
```

In the editor that opens, paste:

```
MONGO_INITDB_ROOT_USERNAME=komodo
MONGO_INITDB_ROOT_PASSWORD=<generate a strong random password>
KOMODO_DATABASE_USERNAME=komodo
KOMODO_DATABASE_PASSWORD=<the same password>
```

Use `openssl rand -base64 32` to generate the password. Save and exit. The `.age` file is written.

- [ ] **Step 4: Create the Komodo core env file**

```bash
nix run github:ryantm/agenix -- -e velomo-alpha/komodo-core-env.age
```

Paste:

```
KOMODO_PASSKEY=<generate a strong random secret, e.g. openssl rand -base64 32>
KOMODO_JWT_SECRET=<generate a strong random secret>
```

Save and exit.

- [ ] **Step 5: Create the periphery env file (mirrors the passkey)**

```bash
nix run github:ryantm/agenix -- -e velomo-alpha/komodo-passkey-env.age
```

Paste — **use the same KOMODO_PASSKEY value as in Step 4**:

```
KOMODO_PASSKEY=<the same passkey from Step 4>
```

Save and exit.

- [ ] **Step 6: Create the Tailscale auth key file**

Get an auth key from the Tailscale admin console (https://login.tailscale.com/admin/settings/keys). Create a reusable / ephemeral key as you prefer.

```bash
nix run github:ryantm/agenix -- -e velomo-alpha/tailscale-authkey.age
```

Paste **only** the auth key string (e.g. `tskey-auth-...`), no quotes, no newlines. Save and exit.

- [ ] **Step 7: Verify all four .age files exist**

```bash
cd ..
ls secrets/velomo-alpha/
```

Expected:
```
komodo-db.age
komodo-core-env.age
komodo-passkey-env.age
tailscale-authkey.age
```

- [ ] **Step 8: Commit (the `.age` files are encrypted blobs — safe to commit)**

```bash
git add secrets/secrets.nix secrets/velomo-alpha/
git commit -m "feat(velomo-alpha): add agenix secrets for Komodo + Tailscale"
```

---

## Task 12: Activate secrets and Komodo on velomo-alpha

**Where:** framework-13 → push, then velomo-alpha → pull + rebuild

- [ ] **Step 1: Fill in `hosts/velomo-alpha/secrets.nix` with real secret declarations**

Replace the placeholder content of `hosts/velomo-alpha/secrets.nix` with:

```nix
{config, ...}: {
  age.secrets = {
    "velomo-alpha/komodo-db" = {
      file = ../../secrets/velomo-alpha/komodo-db.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/komodo-core-env" = {
      file = ../../secrets/velomo-alpha/komodo-core-env.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/komodo-passkey-env" = {
      file = ../../secrets/velomo-alpha/komodo-passkey-env.age;
      owner = "root";
      mode = "400";
    };
    "velomo-alpha/tailscale-authkey" = {
      file = ../../secrets/velomo-alpha/tailscale-authkey.age;
      owner = "root";
      mode = "400";
    };
  };
}
```

- [ ] **Step 2: Update `hosts/velomo-alpha/default.nix` to enable docker + import secrets + services**

Edit `hosts/velomo-alpha/default.nix`. Uncomment the three pending lines and the docker toggle:

```nix
{
  pkgs, lib, inputs, outputs, config, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./configuration.nix
    ../../components/nixos
    inputs.home-manager.nixosModules.home-manager
    ./secrets.nix
    ./services
  ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs outputs;};
  };

  components.virtualization.docker.enable = true;
}
```

- [ ] **Step 3: Add the Tailscale autoconnect systemd unit**

Edit `hosts/velomo-alpha/configuration.nix`. Below the `services.tailscale.enable = true;` line, add:

```nix
  # Auto-connect Tailscale on first boot using the agenix-managed auth key.
  # Idempotent: tailscale up is a no-op if already authenticated.
  systemd.services.tailscale-autoconnect = {
    description = "Authenticate Tailscale on first boot";
    after = ["network-pre.target" "tailscaled.service"];
    wants = ["network-pre.target" "tailscaled.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      sleep 2
      status=$(${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r .BackendState)
      if [ "$status" = "Running" ]; then
        exit 0
      fi
      ${pkgs.tailscale}/bin/tailscale up \
        --authkey "file:${config.age.secrets."velomo-alpha/tailscale-authkey".path}" \
        --ssh
    '';
  };
```

This requires `jq` and `tailscale` to be available. `jq` may need to be in `environment.systemPackages`. Add it:

```nix
  environment.systemPackages = with pkgs; [
    git
    neovim
    htop
    jq         # <-- add
    tailscale  # <-- add (CLI on PATH for ad-hoc use)
  ];
```

- [ ] **Step 4: Commit the activation changes**

```bash
git add hosts/velomo-alpha/
git commit -m "feat(velomo-alpha): activate secrets, docker, komodo, tailscale autoconnect"
git push
```

- [ ] **Step 5: On velomo-alpha, pull and rebuild**

SSH into velomo-alpha:

```bash
ssh nh@<velomo-alpha-ip>
sudo nix-shell -p git --run "git -C /tmp/nixos-config pull"
# Or use a more permanent clone location if you prefer.
cd /tmp/nixos-config
sudo nixos-rebuild switch --flake .#velomo-alpha
```

Expected: builds, switches to the new generation, activates secrets, starts Tailscale, starts the three Komodo containers.

- [ ] **Step 6: Verify the containers are running**

```bash
docker ps
```

Expected: three containers — `mongo`, `komodo-core`, `komodo-periphery` — all in `Up` state.

- [ ] **Step 7: Verify Tailscale connected**

```bash
tailscale status
```

Expected: this machine listed as `velomo-alpha`, peers showing your other Tailnet members.

- [ ] **Step 8: Verify Komodo web UI is reachable**

From framework-13 (on Tailscale):

```bash
curl -sI http://velomo-alpha:9120 | head -1
```

Expected: `HTTP/1.1 200 OK` or `HTTP/1.1 302 Found` (a redirect to the login page).

---

## Task 13: Configure Komodo via the web UI

**Where:** framework-13 web browser → `http://velomo-alpha:9120`

- [ ] **Step 1: Open the Komodo web UI** at `http://velomo-alpha:9120`.

- [ ] **Step 2: Complete the initial admin user setup** (Komodo prompts for a username + password on first visit). The local Periphery should auto-connect because `KOMODO_FIRST_SERVER` points at it.

- [ ] **Step 3: Verify the local server is listed**

In the Komodo UI, navigate to Servers. You should see one server (the local Periphery) in a `Healthy` state.

- [ ] **Step 4: Add the private compose repo as a Git Provider**

In Komodo Settings → Git Accounts (or equivalent — UI varies by version), add a deploy token for the private compose repo. You'll need:
- The repo URL (`https://github.com/<user>/<repo>` or similar)
- A deploy token / personal access token with read access

- [ ] **Step 5: Create a Resource Sync pointing at the compose repo**

In Komodo, create a Resource Sync resource. Configure it to pull from the git repo + path. Trigger a sync. Initially the repo can be empty or contain only a placeholder stack.

- [ ] **Step 6: Add Beszel as the first workload in the compose repo**

In the compose repo (NOT this nixos-config repo), add a compose file with the Beszel Hub + Agent:

```yaml
# beszel.compose.yaml in the velomo-alpha-compose repo
services:
  beszel-hub:
    image: henrygd/beszel:latest
    container_name: beszel-hub
    restart: unless-stopped
    ports:
      - "8090:8090"
    volumes:
      - ./beszel_data:/beszel_data

  beszel-agent:
    image: henrygd/beszel-agent:latest
    container_name: beszel-agent
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./beszel_agent_data:/var/lib/beszel-agent
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      LISTEN: 45876
      KEY: "<paste public key from beszel-hub UI after first start>"
```

Push the compose repo. Trigger Resource Sync in Komodo. Komodo should deploy the stack.

- [ ] **Step 7: Verify Beszel UI**

Open `http://velomo-alpha:8090` (on Tailscale — open the firewall for 8090 on tailscale0 first if needed, or use port-forwarding from Komodo). Confirm dashboards show velomo-alpha's CPU / RAM / disk / network stats.

**Implementation complete.** velomo-alpha is a running, GitOps-deployed homelab server. Future workloads are added by editing the compose repo — no NixOS rebuild required.

---

## Backout / Rollback

If anything in Phase 2/3 breaks the box:

- `sudo nixos-rebuild switch --rollback` reverts to the previous NixOS generation.
- Or boot the previous generation from the systemd-boot menu at startup.
- Docker state under `/var/lib/komodo/` is preserved across generations — mongo data and Komodo keys survive a rollback.

If a Komodo container is stuck:

- `docker ps -a` shows recent containers.
- `docker logs <name>` for diagnostics.
- `systemctl restart docker-<name>.service` to restart an individual container service.
- `systemctl restart docker-mongo.service docker-komodo-core.service docker-komodo-periphery.service` for a full Komodo stack restart.

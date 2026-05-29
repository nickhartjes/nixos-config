# velomo-alpha — Minimal Komodo Server Design

**Date:** 2026-05-29
**Status:** Approved, ready for implementation planning
**Host:** `velomo-alpha` (bare-metal, home lab)

## Goal

Add a new NixOS host to this flake whose only job is to run a Docker-based GitOps deployer. The deployer pulls compose stacks from a private git repo and applies them. The NixOS configuration stays minimal — it provides the engine and the deployer, nothing else.

## High-Level Architecture

Three layers, bottom-up:

1. **NixOS base.** Single-disk ext4 install, systemd-boot, DHCP, Tailscale, OpenSSH (key-only), agenix for secrets, the existing `components.virtualization.docker` toggle. Reuses `components/nixos` and a **slimmed-down user definition** — does NOT reuse the workstation-flavored `users/nh.nix` (see "Server-vs-workstation user split" below).
2. **Komodo bootstrap.** Three containers (mongo, komodo-core, komodo-periphery) declared as `virtualisation.oci-containers` entries in NixOS. Brought up automatically by systemd at boot.
3. **Workloads.** Komodo Resource Sync pulls compose stacks from a private git repo. NixOS knows nothing about these.

**Key principle:** NixOS owns the boot-to-Komodo bootstrap. Komodo owns everything from there.

## Tool Choice — Why Komodo

The user originally asked about doco-cd (a small, single-purpose compose CD tool). After review:

- doco-cd is small (~1k stars, single maintainer) — bus-factor risk.
- **Komodo** (~10k stars, active development) does the same job plus a web UI, image-update tracking, and multi-server support. Modest extra complexity (3-4 containers vs 1) for a much stronger maintenance story.
- Portainer CE was considered but is heavier and feature-rich beyond the goal.
- Plain `git pull + docker compose` via systemd timer was considered as the absolute floor; rejected because the user wants a web UI for visibility.

**Database choice:** MongoDB (3-container setup) rather than FerretDB+Postgres (4-container, fully OSS). The MongoDB SSPL license is irrelevant for private homelab use; we trade license purity for one fewer container.

## Repo Structure

```
hosts/velomo-alpha/
├── default.nix              # entry point — imports configuration + components/nixos directly (NOT hosts/common); sets component toggles
├── configuration.nix        # hostname, locale, networking, time zone, SSH, stateVersion
├── disko-config.nix         # single-disk GPT + ESP + ext4
├── hardware-configuration.nix  # generated on target via nixos-generate-config
├── secrets.nix              # agenix secret declarations
└── services/
    ├── default.nix          # imports ./komodo.nix
    └── komodo.nix           # three oci-containers + systemd glue
```

**Flake wiring** — add to `flake.nix` under `nixosConfigurations`:

```nix
velomo-alpha = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs outputs; };
  modules = [
    ./hosts/velomo-alpha
    inputs.disko.nixosModules.disko
    agenix.nixosModules.default
  ];
};
```

**Component toggles** (in `default.nix`):

```nix
components.virtualization.docker.enable = true;
```

No desktop manager, no display manager, no podman, no specialisations, no GUI packages.

## Disko Layout

Same shape as `vm-blackhawk` but on the actual install disk:

- GPT
- 1 MB BIOS-boot stub (unused with UEFI but harmless)
- 512 MB ESP, vfat, mounted `/boot`
- Remainder: ext4, mounted `/`

The disk device path will be filled in at install time. Default placeholder: `/dev/nvme0n1` (correct for most modern hardware; adjust if the target uses SATA/`/dev/sda`).

No swap partition. If swap is later needed, add a swapfile via NixOS config — not as a partition.

## Networking & Access

- `networking.hostName = "velomo-alpha"`
- `networking.networkmanager.enable = true` (match other hosts), DHCP on the wired interface
- `services.tailscale.enable = true` plus a `tailscale-autoconnect` systemd oneshot that runs `tailscale up --auth-key file://$AUTHKEY` if not connected, where `$AUTHKEY` is an agenix-managed file
- `services.openssh.enable = true` with `PermitRootLogin = "no"` and `PasswordAuthentication = false` (key-only)

**Firewall:**

- `tailscale0` marked as a trusted interface
- LAN: TCP 22 (SSH) only
- Tailscale interface: TCP 9120 (Komodo web UI) opened only on `tailscale0`, not LAN
- Everything else closed

**User account:** See "Server-vs-workstation user split" below for the full rationale. Summary: define an `nh` user inline in `hosts/velomo-alpha/configuration.nix` with just `isNormalUser`, `extraGroups = ["wheel" "docker"]`, `initialHashedPassword`, and `openssh.authorizedKeys.keys` — reusing the public key already in `users/nh.nix`. Skip the workstation tree (`users/nh/secrets.nix`, home-manager, GPG, GUI dotfiles).

## Server-vs-Workstation User Split

`hosts/common/default.nix` imports `../../users`, which pulls in `users/nh.nix`, which imports `users/nh/secrets.nix`. That last file references several agenix secrets (`ssh-framework-13.age`, `gpg-private-key.age`, etc.) that are encrypted with framework-13's keys, not velomo-alpha's. On a fresh server those secrets cannot be decrypted and the activation will fail. The whole tree is also workstation-heavy (full home-manager profile with Plasma manager, dev apps, Obsidian, etc.) — irrelevant to a headless box.

**Decision:** `velomo-alpha` will **not** use `hosts/common/`. Instead, its `default.nix` directly imports `../../components/nixos`, the `home-manager` NixOS module (kept available even if unused), and the host-local files. The `nh` user is defined inline in `configuration.nix` with the minimum needed: `isNormalUser`, password hash, `wheel` + `docker` groups, and the authorized SSH key copied from `users/nh.nix`.

This keeps the existing workstation hosts untouched (no refactor of `users/nh.nix`), at the cost of a small amount of duplicated user-config between this host file and the workstation tree. Acceptable trade-off for "minimal" — the alternative (refactoring `users/` to be server-aware) is larger surface area than this host justifies.

The nixpkgs settings (overlays, `allowUnfree`), Nix daemon settings (GC, optimize-store), and `nix-ld` setup that live in `hosts/common/default.nix` will need to be replicated in `velomo-alpha`'s configuration. The cleanest mechanic is a thin shared module at `hosts/common-base/default.nix` containing just those non-user pieces, imported by both `common/` (refactored) and `velomo-alpha`. Whether to refactor or just inline-copy is left as an implementation-time decision; the spec mandates *only* that the workstation user tree must not be imported.

## Komodo Bootstrap (`services/komodo.nix`)

Three `virtualisation.oci-containers` entries, all on a dedicated `komodo` Docker network. Image tags pinned to a major version (`1`, the current stable as of this date — verify at implementation time before pinning).

### mongo

- Image: `mongo:7`
- Network: `komodo`
- Volume: `/var/lib/komodo/mongo:/data/db`
- Env from secrets: `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`
- No published ports — internal only

### komodo-core

- Image: `ghcr.io/moghtech/komodo-core:1`
- Network: `komodo`
- Published port: `9120:9120` (host port only reachable via firewall rules above)
- Depends on: `mongo`
- Volume: `/var/lib/komodo/core:/config`
- Env from secrets / config:
  - `KOMODO_HOST=http://velomo-alpha:9120` (will be the Tailscale magicdns name in practice)
  - `KOMODO_DATABASE_ADDRESS=mongo:27017`
  - `KOMODO_DATABASE_USERNAME` / `KOMODO_DATABASE_PASSWORD` from agenix
  - `KOMODO_PASSKEY` from agenix
  - `KOMODO_JWT_SECRET` from agenix
  - `KOMODO_FIRST_SERVER=http://komodo-periphery:8120` (auto-onboards the local periphery)

### komodo-periphery

- Image: `ghcr.io/moghtech/komodo-periphery:1`
- Network: `komodo`
- Published port: `8120:8120` bound to `127.0.0.1` (Core reaches it via the Docker network, not the host port; published only for local debugging)
- Volumes:
  - `/var/run/docker.sock:/var/run/docker.sock` — the whole point
  - `/var/lib/komodo/periphery:/etc/komodo`
  - `/opt/stacks:/opt/stacks` — where Komodo materializes pulled compose files
- Env: `KOMODO_PASSKEY` (same as Core), `KOMODO_PORT=8120`

## Secrets (agenix)

New entries in `secrets/secrets.nix` for the `velomo-alpha` system, plus the secret files themselves:

- `secrets/velomo-alpha/komodo-passkey.age` — shared between Core and Periphery
- `secrets/velomo-alpha/komodo-jwt.age` — JWT signing key for Core
- `secrets/velomo-alpha/komodo-db.age` — Mongo root credentials (a single env file with USER + PASSWORD)
- `secrets/velomo-alpha/tailscale-authkey.age` — for first Tailscale connect
- `secrets/velomo-alpha/git-deploy-token.age` — only needed inside Komodo once the UI is up; can be created later

The new host's SSH ed25519 public key is added to `secrets/secrets.nix` after first boot, then secrets are re-encrypted (`agenix --rekey`).

## State on the Host

| Path | Purpose | Backup priority |
|------|---------|----------------|
| `/var/lib/komodo/mongo/` | Mongo data — Komodo's source of truth | **Critical** |
| `/var/lib/komodo/core/` | Komodo encryption keys (losing them breaks secrets decryption) | **Critical** |
| `/var/lib/komodo/periphery/` | Periphery config | Regeneratable |
| `/opt/stacks/` | Materialized compose files from git | Regeneratable |

Backup configuration is **out of scope** for this design but explicitly flagged here for future work.

## Bootstrap & Install Flow

### Phase 0 — Prepare in the repo (minimal floor only)

On `framework-13`, in this nixos-config repo. The goal is to land a configuration that *evaluates cleanly* before any secret files exist — so `nix flake check` and the install both work.

1. Create `hosts/velomo-alpha/` with:
   - A **placeholder** `hardware-configuration.nix` (empty module: `{ ... }: { }`) — to be overwritten by `nixos-generate-config` during the install.
   - `disko-config.nix` (single-disk GPT + ESP + ext4).
   - `configuration.nix` with hostname, locale, NetworkManager, Tailscale (enable only — no autoconnect yet), OpenSSH (key-only), the inline `nh` user with authorized SSH key, and the non-user pieces from `common` (overlays, allowUnfree, nix.gc, nix-ld) either inlined or factored into a small `common-base`.
   - `default.nix` that imports **only** `./configuration.nix`, `./disko-config.nix`, `./hardware-configuration.nix`, `../../components/nixos`, and `inputs.home-manager.nixosModules.home-manager`. Does **not** import `secrets.nix` or `services/` yet.
   - Stubs for `secrets.nix` and `services/komodo.nix` can exist but are not imported.
2. Wire `velomo-alpha` into `flake.nix` under `nixosConfigurations`, including `agenix.nixosModules.default` from the start — it's harmless when no `age.secrets` are declared, and adding it now avoids a later flake.nix touch.
3. Verify with `nix flake check` from `framework-13`.
4. Commit (don't push yet).

### Phase 1 — Bare-metal install on target

5. Boot the official NixOS installer ISO on `velomo-alpha`.
6. Confirm Ethernet has DHCP'd successfully.
7. Clone this repo onto the installer.
8. Generate the real `hardware-configuration.nix`:
   ```bash
   nixos-generate-config --no-filesystems --dir /tmp/hw
   cp /tmp/hw/hardware-configuration.nix ./hosts/velomo-alpha/
   ```
9. Run disko and install:
   ```bash
   sudo nix run github:nix-community/disko -- --mode disko ./hosts/velomo-alpha/disko-config.nix
   sudo nixos-install --flake .#velomo-alpha --no-root-passwd
   ```
10. Reboot.

### Phase 2 — Add to secrets dance

11. From `framework-13`, SSH into `velomo-alpha` as the `nh` user. The framework-13 SSH public key is already baked into the user's `authorizedKeys` (copied from `users/nh.nix` into the inline definition), so this works immediately — no password fallback needed.
12. Read the new host's SSH host public key: `cat /etc/ssh/ssh_host_ed25519_key.pub`.
13. Add an entry for `velomo-alpha` in `secrets/secrets.nix` (both in the `let` block and in per-secret `publicKeys` arrays for the Komodo-specific secrets created next).
14. Create the Komodo-specific secret files (passkey, jwt, db creds, tailscale auth key) with `nix run github:ryantm/agenix -- -e <file>.age`. Encrypted only with the keys that need access — typically `framework-13` (to edit) + `velomo-alpha` (to consume).
15. Re-encrypt any *existing* secrets that need velomo-alpha access (probably none — only the new Komodo secrets need it). `agenix --rekey` if needed.
16. Update `hosts/velomo-alpha/default.nix` to import `./secrets.nix`.
17. Commit, push, and `nixos-rebuild switch` on velomo-alpha — confirm secrets decrypt.
18. Enable Tailscale autoconnect (uncomment / enable the systemd oneshot now that the auth-key secret exists) and rebuild once more.

### Phase 3 — Bring up Komodo

19. Update `hosts/velomo-alpha/default.nix` to set `components.virtualization.docker.enable = true` and import `./services`.
20. Push from `framework-13`, pull on `velomo-alpha`, run `sudo nixos-rebuild switch --flake .#velomo-alpha`.
21. Verify: `docker ps` should show three running containers (`mongo`, `komodo-core`, `komodo-periphery`).

### Phase 4 — Configure Komodo via web UI

22. From `framework-13` (on Tailscale), browse to `http://velomo-alpha:9120`.
23. Complete initial admin user setup.
24. Add the private compose repo as a Git Provider (using a deploy token).
25. Create a Resource Sync pointing at that repo.
26. As the first workload, add **Beszel** (Hub + Agent) to the compose repo. Confirm Komodo deploys it and the Beszel UI is reachable.

## Rollback Story

Every `nixos-rebuild switch` creates a new generation visible in systemd-boot. If a rebuild breaks the box:

- `nixos-rebuild switch --rollback` to revert to the previous generation, or
- Boot the previous generation from the systemd-boot menu.

Docker container state under `/var/lib/komodo/` is preserved across NixOS generations.

## Explicitly Out of Scope

These are intentionally excluded from this design — flagged here so we don't forget:

- **Reverse proxy (Caddy / Traefik)** — can be deployed as a workload via Komodo later.
- **TLS for the Komodo UI** — accessed over Tailscale, which is already encrypted end-to-end.
- **Backups of `/var/lib/komodo/`** — out of scope; needs its own design.
- **fail2ban** — SSH is key-only and Komodo UI is Tailscale-only; brute-force surface is minimal.
- **Automatic upgrades** — flake-driven rebuilds stay manual.
- **specialisations.nix** — not needed.
- **Beszel itself in NixOS** — deployed via Komodo, not baked into the bootstrap.

## Open Items at Implementation Time

- Verify Komodo image major tag (`1` vs `2`) at the moment of implementation — pin to whatever is current stable.
- Confirm the install disk device path before running disko (`/dev/nvme0n1` vs `/dev/sda`).
- Decide the Tailscale magicdns name — likely just `velomo-alpha` if no override is needed.

# n100-nanoclaw: NixOS host running nanoclaw with health MCP servers

**Date:** 2026-08-24
**Status:** Phase A implemented and verified. Phase B (below) not started.

**Scope split:**
- **Phase A** — host, Docker, toolchain, secrets, verification. Done; see
  `docs/superpowers/plans/2026-08-24-n100-nanoclaw-install.md` and its
  verification record.
- **Phase B** — the nanoclaw service itself, MCP wiring, vault sync. Not
  started. The "MCP wiring" section below is design intent only, and has been
  corrected to match `docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md`,
  which is the authority on what upstream nanoclaw actually supports.

## Goal

Install NixOS on a spare Intel N100 mini-PC as a new host
`n100-nanoclaw`, and run [nanoclaw](https://github.com/nanocoai/nanoclaw)
on it: a Telegram-fronted AI assistant that executes agents in Docker
containers. The agent must reach Nick's personal training data through
three MCP servers (Strava, Hevy, Google Health) and must be able to run
the `update-training-data` workflow against the Obsidian vault without
racing framework-13 for the same files.

## Context

### Verified target hardware (inspected 2026-08-24 over SSH)

| Property | Value |
|---|---|
| Chassis / CPU | T100, Intel N100, 4 cores |
| RAM | 15 GiB |
| Disk | `/dev/nvme0n1`, GOFATOO SSD, 512 GB (476.9 GiB), SMART PASSED |
| Firmware | UEFI, Secure Boot disabled (setup mode) |
| NIC | `enp3s0`, 10.0.60.51/24 |

The disk currently holds a single whole-disk XFS partition containing an
orphaned **Longhorn** (Kubernetes distributed storage) volume: 18 GB
across 22 PVC replicas, engine v1.6.1, last written **2024-07-10**. It is
not the `n100nas` box (that node was online on the tailnet while this
machine ran a live ISO). Nick confirmed on 2026-08-24 that this is a dead
node and the disk may be wiped.

Because the firmware is UEFI with Secure Boot off, plain `systemd-boot`
is sufficient; the `lanzaboote` setup used on framework-13 is not needed.

### Why nanoclaw is not packaged declaratively

nanoclaw's stated design is "customization = code changes": you fork it
and let Claude Code edit your fork. Channels are not even in trunk —
`/add-telegram` copies code from a `channels` branch into the working
tree. Packaging that as a Nix derivation would fight the project's model
and break on every `/add-<channel>`.

The design therefore splits responsibility:

- **NixOS declares the platform** — host config, Docker, Node/pnpm,
  claude-code, agenix secrets, the systemd unit, backups.
- **nanoclaw's checkout stays a mutable git clone** at
  `/home/nh/nanoclaw`, owned by `nh`.

This is a deliberate boundary, not a purity failure.

### Why it runs as `nh`, not a dedicated user

Whoever runs nanoclaw's host process needs the Docker socket, and Docker
socket access is root-equivalent. A dedicated UID therefore buys no
security boundary against a compromised agent — it only relocates files
and adds `sudo -u` friction to `claude login`, `/customize`, and editing
the fork, which are the operations this box exists for. The real
isolation boundary is that this is a separate machine.

## Architecture

```
Telegram  ──►  nanoclaw host process (systemd, user nh)
                      │  inbound.db / outbound.db (SQLite, file-based)
                      ▼
              agent container (Docker, per agent group)
                      │
                      │   $HOME=/home/node
                      ├─ MCP config: container.json `mcpServers`, or a
                      │   group-folder .mcp.json via the SDK's
                      │   settingSources — UNRESOLVED, see findings doc
                      │     strava (http, OAuth)
                      │     hevy (stdio, API key)
                      │     google-health (stdio, OAuth)
                      └─ mounts: forced under /workspace/extra/…
```

## Changes

### `flake.nix`

Add a `nixosConfigurations.n100-nanoclaw` entry, modelled on
`velomo-alpha` — modules are `./hosts/n100-nanoclaw`,
`inputs.disko.nixosModules.disko`, and `agenix.nixosModules.default`.
No `nixos-hardware`, no compositor modules, no lanzaboote.

### `hosts/n100-nanoclaw/` (new)

Mirrors the `velomo-alpha` layout, which is the repo's existing
headless-Docker-host pattern.

- **`default.nix`** — imports `hardware-configuration.nix`,
  `disko-config.nix`, `configuration.nix`, `secrets.nix`, `services/`,
  plus `../../components/nixos/{system,hardware,virtualization}`.
  Sets `components.virtualization.docker.enable = true`. Wires
  home-manager's `extraSpecialArgs` without loading HM user modules
  (same as velomo-alpha).
- **`configuration.nix`** — `systemd-boot` + `canTouchEfiVariables`;
  the four repo overlays and `allowUnfree`; the standard `nix` daemon
  block (flakes, weekly GC, auto-optimise); hostname `n100-nanoclaw`;
  `time.timeZone = "Europe/Amsterdam"`; NetworkManager; Tailscale with
  Tailscale enabled but authorised once by hand with `tailscale up --ssh`
  (velomo-alpha's `tailscale-autoconnect` oneshot is deliberately not
  copied: it needs a tailscale-authkey secret, and this host already
  requires a hands-on session for `claude login` and the OAuth flows);
  OpenSSH
  with `PermitRootLogin = "no"` and `PasswordAuthentication = false`;
  firewall allowing only TCP 22 with `tailscale0` trusted. User `nh`
  defined **inline** (not importing `users/nh.nix`, which assumes
  framework-13 keys and a full HM profile), in groups `wheel`,
  `networkmanager`, `docker`, with both framework-13 public keys.
  `system.stateVersion = "26.11"` — the release the flake's
  nixpkgs-unstable resolves to at install date, not the 25.11 ISO's.
- **`disko-config.nix`** — `/dev/nvme0n1`, GPT: 1 MiB `EF02` BIOS-boot,
  512 MiB `EF00` ESP (vfat, `/boot`), remainder ext4 at `/`. Copied from
  velomo-alpha with the device path confirmed. No impermanence — with
  subscription OAuth, `/home/nh` persisting trivially is a feature.
- **`hardware-configuration.nix`** — generated during install.
- **`secrets.nix`** — see Secrets below.
- **`services/default.nix`** — imports `nanoclaw.nix`.
- **`services/nanoclaw.nix`** — the systemd unit.

### System packages

`nodejs_22` (22.23.2), `pnpm` (11.21.0), `claude-code` (2.1.238), `bun`,
plus `git`, `jq`, `htop`, `neovim`, `tailscale`. Upstream asks for
pnpm 10+; nixpkgs ships 11, which should be compatible but is a watch
point.

### `systemd.services.nanoclaw`

```
User=nh
WorkingDirectory=/home/nh/nanoclaw
SupplementaryGroups=docker
After=docker.service network-online.target
Restart=on-failure
RestartSec=10s
EnvironmentFile=<agenix telegram token>
ConditionPathExists=/home/nh/nanoclaw/package.json
```

`ConditionPathExists` keeps the unit inert rather than crash-looping
before the checkout is bootstrapped. Logs go to journald.

## Secrets (agenix)

Add to `secrets/secrets.nix`, encrypted to the new host key plus Nick's
two framework-13 user keys, following the existing per-host grouping:

| Secret | Purpose | Decrypted to |
|---|---|---|
| `n100-nanoclaw/telegram-bot-token.env` | `TELEGRAM_BOT_TOKEN` for the channel | `/run/agenix`, read via `EnvironmentFile` |
| `n100-nanoclaw/hevy-api-key` | `HEVY_API_KEY` for the hevy MCP | `/home/nh/.config/hevy-mcp.env`, `owner = nh`, `mode = 400` |
| `n100-nanoclaw/obsidian-deploy-key` | SSH key to push the vault | `/home/nh/.ssh/id_obsidian`, `owner = nh`, `mode = 400` |

The hevy secret reuses the exact pattern already in
`hosts/framework-13/secrets.nix`. `identityPaths` is left at its default
(`/etc/ssh/ssh_host_ed25519_key` is picked up automatically); the
framework-13 `mkForce` workaround is not needed because this host has no
impermanence and no `users/nh/secrets.nix` import.

**The two OAuth tokens are deliberately not in agenix.** They are
refreshable host-local state, not deployable secrets.

The deploy key must be registered on the `nickhartjes/obsidian` GitHub
repo as a **deploy key with write access**.

## MCP wiring

**Authority for this section:**
`docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md` verifies
these claims against upstream nanoclaw source (file/line citations); the
design below has been corrected to match it, not the other way around.
Re-check that document before implementing Phase B — the findings note the
upstream commit is a moving target.

The Claude Agent SDK runs *inside* the agent container, so MCP servers
must work there — not on the host. The container's `$HOME` is `/home/node`
(settled: baked into the `node:22-slim` image's `USER node`, and explicitly
set by nanoclaw's own container-spawn code when running under a mapped uid).

MCP servers are configured per-group via `container.json`'s `mcpServers`
field (materialized by nanoclaw from the DB, editable with
`ncl groups config add-mcp-server`), not via a plain `.mcp.json` dropped in
the group folder — **whether a `.mcp.json` at `groups/<folder>/.mcp.json`
(which lands at `/workspace/agent/.mcp.json`) is also picked up by the SDK's
`settingSources: ['project','user','local']` option is UNRESOLVED.** The
findings doc confirms the option is real and forwarded to the underlying
`claude` CLI subprocess, but the actual file-reading/auto-approval logic
lives in that compiled binary and was not inspected. Do not assume either
way; settle it with the drop-and-restart experiment the findings doc
describes (drop a minimal `.mcp.json` into an existing group folder,
`ncl groups restart`, check for the probe server in the agent's tool list)
before designing around it.

Google Health and Strava need no host-side file at all
(`google-health` runs via `npx`; `strava` is a plain `http` MCP entry), so
both can go directly into `container.json`'s `mcpServers` with
`ncl groups config add-mcp-server`.

**The hevy API key does not need a bind-mounted `~/.config/hevy-mcp.env`.**
There is no per-group env mechanism — `ContainerConfig` is an exhaustive
TypeScript type with no room for one — but there *is* a per-MCP-server `env`
field (`mcpServers.<name>.env`, capped at 32 entries), which is the
supported way to deliver `HEVY_API_KEY`:

```
ncl groups config add-mcp-server --id <group-id> --name hevy \
  --command npx --args '["-y","hevy-mcp"]' \
  --env '{"HEVY_API_KEY":"<value from agenix-decrypted hevy-api-key>"}'
```

If a file on disk is preferred instead of a DB-stored env value, `additionalMounts`
does support bind-mounting the agenix-decrypted `hevy-mcp.env` file into the
container — but **the container path is always forced under
`/workspace/extra/…`**; there is no way to land it at a literal
`/home/node/.config/hevy-mcp.env`. In that case the hevy MCP command must
source it from `/workspace/extra/hevy-mcp.env` explicitly (e.g.
`sh -c '. /workspace/extra/hevy-mcp.env && exec npx -y hevy-mcp'`), not rely
on `$HOME` resolving to a mounted-over `.config`.

**Persistent credentials volume.** Both OAuth tokens and the Claude
subscription credential live in dotfile state a throwaway container would
lose. A host directory (`/home/nh/nanoclaw-state/creds`) is mounted into
the agent container as its home-config path, seeded once interactively,
and is the primary backup target.

**Bake the npm packages into the agent image** rather than resolving
`npx -y` on every container start. Editing the image is on-model for a
nanoclaw fork and removes a startup-time network dependency.

## Vault sync

Nick wants the N100 agent to run the training update, with pull-and-commit
mechanically enforced. Enforcement is a **wrapper script**, not prose in
a `CLAUDE.md`, because agents skip prose instructions:

1. `git add -A && git commit` — commit local work first, so a dirty tree
   cannot break the pull
2. `git pull --rebase --autostash`
3. run the `update-training-data` workflow
4. `git add -A && git commit && git push`
5. **on conflict: stop, push nothing, report to Nick over Telegram**

`git push --force` is explicitly rejected: a force-push from the N100
would silently destroy framework-13 commits.

Obsidian workspace state was untracked and gitignored on 2026-08-24
(vault commit `917764d`) so automated commits stay clean.

## Install procedure

nixos-anywhere drives disko; disko remains the disk declaration. The key
advantage is `--extra-files`, which places the SSH host key before first
activation so **agenix decrypts on first boot** — no install-then-rekey
second pass.

1. Generate the host keypair on framework-13 into
   `$tmp/etc/ssh/ssh_host_ed25519_key`, `chmod 600` (nixos-anywhere
   requires this or sshd rejects the key).
2. Add the public key to `secrets/secrets.nix`, create the three
   secrets, `agenix -r`.
3. Commit the host config.
4. `nix run github:nix-community/nixos-anywhere -- --extra-files $tmp
   --flake .#n100-nanoclaw root@10.0.60.51`
5. Reboot; verify agenix, Docker, Tailscale.
6. Clone the nanoclaw fork to `/home/nh/nanoclaw`, run `nanoclaw.sh`,
   pair Telegram, `claude login`, complete the Strava and Google Health
   OAuth flows (SSH port-forward from framework-13 to the box's loopback
   callback).
7. Enable and start `systemd.services.nanoclaw`.

Add a `just install-nanoclaw IP` recipe wrapping step 4, consistent with
the justfile's existing `nix run github:...` usage.

## Out of scope

- Packaging nanoclaw as a Nix derivation.
- Running nanoclaw's host process in its own container (nanoclaw spawns
  Docker containers itself; that needs docker-in-docker or socket
  passthrough, which discards the isolation it would buy).
- Secure Boot / lanzaboote on this host.
- Impermanence, ZFS, or disk encryption.
- Moving vault write authority off framework-13 — both machines write,
  serialised by the git wrapper.
- Fixing the 44 Dependabot advisories on the obsidian repo.

## Risks and unknowns

1. **The load-bearing unknown: nanoclaw's per-group container config
   format is unverified.** The whole MCP design assumes it supports
   arbitrary volume mounts and env injection. The README implies it does
   ("agents can only see what's explicitly mounted"), but this must be
   the first thing the implementation plan verifies. Fallback: patch the
   container spawn in the fork — on-model, but more work.
2. **`google-health-mcp-unofficial` token storage path is unverified**,
   so the exact directory to persist is unknown until bootstrap.
3. **Two interactive OAuth flows on a headless box.** Both need a browser
   callback via SSH port-forward. Fiddly, and the unofficial Google
   Health package is fragile — the vault's own `Training/AGENTS.md`
   already treats "Google Health token expired" as routine. The agent
   should report MCP outages over Telegram rather than fail silently.
4. **Claude subscription OAuth for an always-on agent** will hit session
   rate limits harder than metered API use, and the token is host-local
   state to redo after any reinstall. Accepted deliberately.
5. **Concurrent vault edits** still produce conflicts; the wrapper
   detects and reports rather than resolving them.

## Verification

- `nix flake check` passes; `just build n100-nanoclaw` builds.
- Post-install: `ls /run/agenix` shows all three secrets decrypted;
  `docker info` succeeds as `nh`; `tailscale status` shows the host.
- `systemctl status nanoclaw` is active; journald shows Telegram
  connected.
- From Telegram, the agent answers a question requiring each MCP server
  in turn (a Strava activity, a Hevy body measurement, a Google Health
  sleep figure).
- The vault wrapper runs end-to-end: pull, update, commit, push, with a
  clean `git status` on both machines afterwards.

## Rollback

The host is new and isolated, so rollback is bounded: `systemctl disable
--now nanoclaw` stops the service; removing the flake entry and the
`hosts/n100-nanoclaw/` directory reverts the repo. Nothing on
framework-13 or velomo-alpha changes. The one non-reversible step is
wiping the Longhorn disk, explicitly authorised on 2026-08-24.

# n100-nanoclaw Host Install Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install NixOS on the spare Intel N100 as a new declared host `n100-nanoclaw`, with Docker, the nanoclaw toolchain, Tailscale and agenix secrets all working on first boot.

**Architecture:** A headless host modelled on the repo's existing `velomo-alpha` pattern. disko declares the disk; nixos-anywhere drives the install remotely from framework-13 and uses `--extra-files` to seed the SSH host key *before* first activation, so agenix decrypts on the very first boot instead of needing an install-then-rekey second pass.

**Tech Stack:** NixOS (nixpkgs-unstable, release 26.11), disko, nixos-anywhere, agenix, Docker, Tailscale, systemd-boot.

**Spec:** `docs/superpowers/specs/2026-08-24-n100-nanoclaw-design.md`

**Scope:** This plan covers **Phase A only** — a working, verified NixOS host. Phase B (the nanoclaw service, MCP wiring, vault sync) is a separate plan, deliberately written *after* Task 1 here resolves the container-config unknown that Phase B's design rests on.

## Global Constraints

Copied verbatim from the spec. Every task's requirements implicitly include this section.

- Hostname: `n100-nanoclaw`
- Target: `10.0.60.51`, NIC `enp3s0`, currently running the NixOS 25.11 graphical live ISO
- Disk: `/dev/nvme0n1` (512 GB GOFATOO NVMe). **Wiping is authorised** — it holds only an orphaned Longhorn k8s volume last written 2024-07-10
- Firmware: UEFI, Secure Boot disabled → plain `systemd-boot`. **Do not** add lanzaboote
- `system.stateVersion = "26.11"` — the release the flake's nixpkgs-unstable resolves to, *not* the 25.11 ISO's
- `time.timeZone = "Europe/Amsterdam"`
- Toolchain: `nodejs_22` (22.23.2), `pnpm` (11.21.0 — upstream floor is 10+), `claude-code` (2.1.238), `bun` (1.3.13)
- Service identity: user `nh`, checkout at `/home/nh/nanoclaw`
- No impermanence, no ZFS, no disk encryption
- SSH: `PermitRootLogin = "no"`, `PasswordAuthentication = false`
- Firewall: TCP 22 only, `tailscale0` a trusted interface
- Never `git push --force`

### Two repo-specific traps

1. **`nix` ignores untracked files.** A flake evaluation cannot see a file you have not `git add`ed. Every task that adds a new `.nix` file must `git add` it *before* running any build, or you get a confusing "file does not exist" error.
2. **Do not use `components.system.tailscale`.** That module pulls in `trayscale` (a GTK4/libadwaita tray GUI) and a `graphical-session` user service — wrong for a headless box. This is exactly why `velomo-alpha` inlines `services.tailscale.enable` in its own `configuration.nix`. Inline it here too.

---

### Task 1: Verify nanoclaw's per-group container config supports mounts and env injection

The entire Phase B MCP design assumes the agent container can be given bind mounts and environment variables. The spec records this as inferred from upstream docs, not verified. Resolve it before Phase B is planned. No host changes here — this is a read-only investigation on framework-13.

**Files:**
- Create: `docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md`

**Interfaces:**
- Consumes: nothing
- Produces: a findings document stating (a) whether per-group bind mounts are supported and by what config key, (b) whether per-group env vars are supported and by what key, (c) where the agent container's `$HOME` resolves, (d) whether an `.mcp.json` in the group folder is read by the in-container agent. Phase B's plan is written against these four answers.

- [ ] **Step 1: Clone upstream nanoclaw to a scratch directory**

```bash
git clone --depth 1 https://github.com/nanocoai/nanoclaw \
  /tmp/claude-1001/nanoclaw-src
```

- [ ] **Step 2: Locate the container spawn code**

```bash
cd /tmp/claude-1001/nanoclaw-src
command grep -rniE "docker (run|create)|createContainer|-v |--mount|binds?:" \
  --include='*.ts' --include='*.js' src/ 2>/dev/null | head -40
```

Expected: one or two files that build the container invocation. Read them in full.

- [ ] **Step 3: Locate the group config schema**

```bash
command grep -rniE "groups/|groupConfig|container\.json|settings\.json" \
  --include='*.ts' src/ | head -30
ls groups/ 2>/dev/null || echo "no groups dir in trunk"
```

- [ ] **Step 4: Answer the four questions in writing**

Write `docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md` with a
section per question, each citing the exact source file and line that
justifies the answer. Where the answer is "not supported", state the
smallest patch to the fork that would add it.

Do not write "appears to" or "probably" — if the code does not settle a
question, say "unresolved" and state what runtime experiment would settle it.

- [ ] **Step 5: Commit**

```bash
cd /home/nh/.config/nixos-config
git add docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md
git commit -m "docs(nanoclaw): verify container mount and env support upstream"
```

---

### Task 2: Declare the host so it builds

**Files:**
- Create: `hosts/n100-nanoclaw/hardware-configuration.nix`
- Create: `hosts/n100-nanoclaw/disko-config.nix`
- Create: `hosts/n100-nanoclaw/configuration.nix`
- Create: `hosts/n100-nanoclaw/default.nix`
- Modify: `flake.nix` (add `nixosConfigurations.n100-nanoclaw` after the `velomo-alpha` entry)

**Interfaces:**
- Consumes: nothing
- Produces: a buildable `nixosConfigurations.n100-nanoclaw`. Task 3 adds `./secrets.nix` to this host's `imports`; Task 4 installs this exact attribute name.

- [ ] **Step 1: Verify the build fails now (the attribute does not exist)**

```bash
cd /home/nh/.config/nixos-config
nix eval .#nixosConfigurations.n100-nanoclaw.config.networking.hostName
```

Expected: FAIL — `error: attribute 'n100-nanoclaw' missing`.

- [ ] **Step 2: Write `hosts/n100-nanoclaw/hardware-configuration.nix`**

This is the real output of `nixos-generate-config --no-filesystems --show-hardware-config` run on the target's live ISO on 2026-08-24. `--no-filesystems` is deliberate: disko owns `fileSystems`.

```nix
# Generated by `nixos-generate-config --no-filesystems --show-hardware-config`
# on the target's live ISO, 2026-08-24. fileSystems are owned by disko.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" "rtsx_usb_sdmmc"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
```

- [ ] **Step 3: Write `hosts/n100-nanoclaw/disko-config.nix`**

The `EF02` partition makes the disk bootable under legacy BIOS too. The target is UEFI, so it is redundant insurance, kept for parity with `velomo-alpha`.

```nix
{
  disko.devices = {
    disk = {
      nixos = {
        type = "disk";
        # Confirmed on the target 2026-08-24: single 512 GB GOFATOO NVMe.
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

- [ ] **Step 4: Write `hosts/n100-nanoclaw/configuration.nix`**

```nix
{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: {
  # ---- Bootloader: UEFI with Secure Boot disabled, so plain systemd-boot.
  # Deliberately NOT lanzaboote (framework-13 needs it; this host does not).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- Nixpkgs. allowUnfree is required for claude-code.
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  # ---- Nix daemon (same shape as velomo-alpha)
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = ["root" "@wheel"];
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

  # ---- Identity
  networking.hostName = "n100-nanoclaw";
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- Networking
  networking.networkmanager.enable = true;

  # ---- Tailscale.
  # Inlined on purpose: components.system.tailscale drags in trayscale (a GTK4
  # tray GUI) and a graphical-session user unit, which is wrong for a headless
  # host. velomo-alpha inlines it for the same reason.
  services.tailscale.enable = true;

  # DEVIATION FROM SPEC: no tailscale-autoconnect oneshot. The spec calls for
  # velomo-alpha's unit, but that unit reads a tailscale-authkey agenix secret
  # the spec never lists — the spec is self-inconsistent there. Since this host
  # already needs a hands-on session for `claude login` and two OAuth flows, one
  # `tailscale up --ssh` costs nothing and removes an authkey secret from the
  # design. Revisit if this host is ever rebuilt unattended.

  # ---- SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # ---- User nh, defined inline.
  # Do NOT import users/nh.nix: it assumes framework-13's keys and a full
  # home-manager profile. Same reasoning as velomo-alpha.
  users.users.nh = {
    isNormalUser = true;
    description = "nh";
    home = "/home/nh";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      # framework-13 user keys, kept in sync with secrets/secrets.nix
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
    ];
    shell = pkgs.bash;
  };

  # ---- Packages: the nanoclaw toolchain plus basic operator tools.
  # Upstream asks for pnpm 10+; nixpkgs ships 11.21.0.
  environment.systemPackages = with pkgs; [
    nodejs_22
    pnpm
    bun
    claude-code
    git
    jq
    htop
    neovim
    tailscale
  ];

  # ---- Firewall. nanoclaw needs no inbound ports: it dials out to Telegram.
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedTCPPorts = [22];
  };

  # ---- stateVersion: the release this host was first installed against.
  system.stateVersion = "26.11";
}
```

- [ ] **Step 5: Write `hosts/n100-nanoclaw/default.nix`**

`./secrets.nix` and `./services` are absent on purpose — Task 3 adds the
former, Phase B the latter.

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
    # Server-relevant components only. desktop-manager is skipped: it needs
    # the mango/niri nixos modules, which a headless host does not load.
    ../../components/nixos/system
    ../../components/nixos/hardware
    ../../components/nixos/virtualization
    inputs.home-manager.nixosModules.home-manager
  ];

  # home-manager wiring kept available even though no HM user modules load.
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs outputs;};
  };

  components.virtualization.docker.enable = true;
}
```

- [ ] **Step 6: Add the flake entry**

In `flake.nix`, directly after the closing `};` of the `velomo-alpha` entry
and before the `};` that closes `nixosConfigurations`, insert:

```nix
      # Headless N100: NixOS + Docker + nanoclaw (Telegram-fronted agent host).
      n100-nanoclaw = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/n100-nanoclaw
          inputs.disko.nixosModules.disko
          agenix.nixosModules.default
        ];
      };
```

- [ ] **Step 7: Stage the new files — required before any build**

Nix cannot see untracked files. Skipping this makes Step 8 fail with a
misleading path error.

```bash
cd /home/nh/.config/nixos-config
git add hosts/n100-nanoclaw flake.nix
```

- [ ] **Step 8: Verify evaluation now succeeds**

```bash
nix eval .#nixosConfigurations.n100-nanoclaw.config.networking.hostName
```

Expected: PASS, printing `"n100-nanoclaw"`.

- [ ] **Step 9: Verify the whole system builds**

```bash
just build n100-nanoclaw
```

Expected: PASS, producing a `result` symlink. This is the real gate — it
proves the module set is coherent, including the disko and agenix modules.

Do **not** gate this task on `just check` (`nix flake check`): it evaluates
every host in the repo, so a pre-existing failure elsewhere would block a
change that is fine. Run it if you want, but judge this task on the build.

- [ ] **Step 10: Confirm the bootloader and stateVersion resolved as intended**

```bash
nix eval .#nixosConfigurations.n100-nanoclaw.config.system.stateVersion
nix eval .#nixosConfigurations.n100-nanoclaw.config.boot.loader.systemd-boot.enable
```

Expected: `"26.11"` and `true`.

- [ ] **Step 11: Commit**

```bash
git add hosts/n100-nanoclaw flake.nix
git commit -m "feat(n100-nanoclaw): declare headless NixOS host for nanoclaw"
```

---

### Task 3: Create the host key and agenix secrets

**Files:**
- Create: `hosts/n100-nanoclaw/secrets.nix`
- Modify: `hosts/n100-nanoclaw/default.nix` (add `./secrets.nix` to `imports`)
- Modify: `secrets/secrets.nix` (add the host as a recipient, register three secrets)
- Create: `secrets/n100-nanoclaw/telegram-bot-token.env.age`
- Create: `secrets/n100-nanoclaw/hevy-api-key.age`
- Create: `secrets/n100-nanoclaw/obsidian-deploy-key.age`

**Interfaces:**
- Consumes: `nixosConfigurations.n100-nanoclaw` from Task 2
- Produces: the host keypair at `/tmp/n100-nanoclaw-extra/etc/ssh/ssh_host_ed25519_key`, consumed by Task 4's `--extra-files`. Also produces three decrypted runtime paths Phase B depends on: the Telegram env file under `/run/agenix`, `/home/nh/.config/hevy-mcp.env`, and `/home/nh/.ssh/id_obsidian`.

**Critical:** `agenix -e` overrides `EDITOR` to `cp -- /dev/stdin` whenever stdin is not a TTY (`[ -t 0 ] || EDITOR='cp -- /dev/stdin'` in its wrapper). An `EDITOR="cp /tmp/staged"` trick is silently discarded and yields an **empty** `.age` file with exit code 0. Always pipe plaintext on stdin. A secret must also be registered in `secrets/secrets.nix` *before* `agenix -e` will touch it, or it errors with "attribute missing".

- [ ] **Step 1: Generate the host keypair into the extra-files tree**

The `chmod 600` is mandatory — nixos-anywhere's docs note sshd rejects a
host key with looser permissions.

```bash
mkdir -p /tmp/n100-nanoclaw-extra/etc/ssh
ssh-keygen -t ed25519 -N "" -C root@n100-nanoclaw \
  -f /tmp/n100-nanoclaw-extra/etc/ssh/ssh_host_ed25519_key
chmod 600 /tmp/n100-nanoclaw-extra/etc/ssh/ssh_host_ed25519_key
cat /tmp/n100-nanoclaw-extra/etc/ssh/ssh_host_ed25519_key.pub
```

Keep that public key for Step 2. Do not delete `/tmp/n100-nanoclaw-extra`
before Task 4 completes.

- [ ] **Step 2: Register the host and its secrets in `secrets/secrets.nix`**

In the `let` block, after the `velomo-alpha` binding, add the public key
printed in Step 1:

```nix
  n100-nanoclaw = "<paste the ssh-ed25519 public key from Step 1>";
```

Then after `velomoSystems`, add:

```nix
  nanoclawSystems = [n100-nanoclaw];
```

Then at the end of the attribute set, before the closing `}`:

```nix
  # Telegram bot token for the nanoclaw channel. Contents:
  #   TELEGRAM_BOT_TOKEN=...
  # Read by systemd.services.nanoclaw via EnvironmentFile.
  "n100-nanoclaw/telegram-bot-token.env.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;

  # Hevy API key (export HEVY_API_KEY=...) for the hevy MCP server. Same
  # pattern as framework-13/hevy-api-key: decrypted to a file the hevy
  # stdio server sources. Must be bind-mounted into the agent container.
  "n100-nanoclaw/hevy-api-key.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;

  # SSH private key used to push the Obsidian vault. Registered on
  # github.com/nickhartjes/obsidian as a deploy key with write access.
  "n100-nanoclaw/obsidian-deploy-key.age".publicKeys = [framework-13 framework-13-2] ++ nanoclawSystems;
```

- [ ] **Step 3: Stage the change so agenix can evaluate the rules**

```bash
cd /home/nh/.config/nixos-config
git add secrets/secrets.nix
```

- [ ] **Step 4: Create the three encrypted secrets, piping plaintext on stdin**

Run from `secrets/`, since the keys in `secrets.nix` are relative to it.
Substitute the real Telegram token and Hevy key.

```bash
cd /home/nh/.config/nixos-config/secrets
mkdir -p n100-nanoclaw

printf 'TELEGRAM_BOT_TOKEN=%s\n' '<real-bot-token>' \
  | agenix -e n100-nanoclaw/telegram-bot-token.env.age

printf 'export HEVY_API_KEY=%s\n' '<real-hevy-key>' \
  | agenix -e n100-nanoclaw/hevy-api-key.age

ssh-keygen -t ed25519 -N "" -C nanoclaw-obsidian-deploy -f /tmp/obsidian-deploy
agenix -e n100-nanoclaw/obsidian-deploy-key.age < /tmp/obsidian-deploy
cat /tmp/obsidian-deploy.pub   # register this on GitHub in Step 5
```

- [ ] **Step 5: Verify the round-trip without printing secrets**

An empty file is the exact failure mode the EDITOR override causes, so
check byte counts, never contents.

```bash
cd /home/nh/.config/nixos-config/secrets
for f in n100-nanoclaw/*.age; do
  printf '%s: %s bytes decrypted\n' "$f" "$(agenix -d "$f" | wc -c)"
done
```

Expected: every line shows a byte count well above zero. A `0` means the
stdin pipe did not take — redo Step 4 for that file.

Then register `/tmp/obsidian-deploy.pub` as a **deploy key with write
access** on `github.com/nickhartjes/obsidian`, and shred the local copies:

```bash
shred -u /tmp/obsidian-deploy /tmp/obsidian-deploy.pub
```

- [ ] **Step 6: Write `hosts/n100-nanoclaw/secrets.nix`**

`identityPaths` is left at the agenix default, which already includes
`/etc/ssh/ssh_host_ed25519_key`. The `lib.mkForce` workaround in
`hosts/framework-13/secrets.nix` exists because that host has
impermanence and imports `users/nh/secrets.nix`; neither applies here.

```nix
{config, ...}: {
  age.secrets = {
    # Telegram bot token, read by systemd.services.nanoclaw (Phase B) via
    # EnvironmentFile. Stays under /run/agenix; root-only is fine because
    # systemd reads EnvironmentFile as root before dropping to nh.
    "n100-nanoclaw/telegram-bot-token.env" = {
      file = ../../secrets/n100-nanoclaw/telegram-bot-token.env.age;
      owner = "root";
      mode = "400";
    };
    # Hevy API key. Decrypted to the path the hevy MCP server sources.
    # owner=nh so the user's process can read it.
    "n100-nanoclaw/hevy-api-key" = {
      file = ../../secrets/n100-nanoclaw/hevy-api-key.age;
      path = "/home/nh/.config/hevy-mcp.env";
      owner = "nh";
      mode = "400";
    };
    # Deploy key for pushing the Obsidian vault.
    "n100-nanoclaw/obsidian-deploy-key" = {
      file = ../../secrets/n100-nanoclaw/obsidian-deploy-key.age;
      path = "/home/nh/.ssh/id_obsidian";
      owner = "nh";
      mode = "400";
    };
  };
}
```

- [ ] **Step 7: Import it from the host**

In `hosts/n100-nanoclaw/default.nix`, add `./secrets.nix` to `imports`,
after `inputs.home-manager.nixosModules.home-manager`.

- [ ] **Step 8: Stage and verify the build still passes**

```bash
cd /home/nh/.config/nixos-config
git add hosts/n100-nanoclaw secrets
nixos-rebuild build --flake .#n100-nanoclaw
```

Expected: PASS. A failure naming a missing `.age` path means Step 4 did not
create that file.

- [ ] **Step 9: Confirm the secrets resolved into the config**

```bash
nix eval --json \
  .#nixosConfigurations.n100-nanoclaw.config.age.secrets \
  --apply 's: builtins.attrNames s'
```

Expected: the three secret names.

- [ ] **Step 10: Commit**

```bash
git add hosts/n100-nanoclaw secrets
git commit -m "feat(n100-nanoclaw): add agenix secrets and host key recipient"
```

---

### Task 4: Install with nixos-anywhere

This is the destructive step. `/dev/nvme0n1` is wiped. Authorised in the spec.

**Files:**
- Modify: `justfile` (add an `install-nanoclaw` recipe)

**Interfaces:**
- Consumes: the buildable host from Task 2, the keypair and secrets from Task 3
- Produces: a booted machine reachable as `nh@10.0.60.51` by SSH key, with `/run/agenix` populated

- [ ] **Step 1: Add the justfile recipe**

Matches the existing `nix run github:...` style used by `deadcode`,
`formatter` and `clean-install`.

```make
# Install a host remotely with nixos-anywhere. Seeds the SSH host key from
# EXTRA (a dir mirroring the target's /), so agenix decrypts on first boot.
# Usage: just install-nanoclaw 10.0.60.51 /tmp/n100-nanoclaw-extra
install-nanoclaw IP EXTRA="/tmp/n100-nanoclaw-extra":
    nix run github:nix-community/nixos-anywhere -- \
      --extra-files {{EXTRA}} \
      --flake .#n100-nanoclaw \
      root@{{IP}}
```

- [ ] **Step 2: Confirm the target is reachable and still the live ISO**

```bash
ssh -o StrictHostKeyChecking=accept-new root@10.0.60.51 \
  'hostname; lsblk -o NAME,SIZE,FSTYPE /dev/nvme0n1'
```

Expected: hostname `nixos`, and the single XFS partition. If root SSH is
refused, the live ISO needs `sudo passwd root` (or your key in
`/root/.ssh/authorized_keys`) — the official ISO ships root with an empty
password, which sshd will not accept.

**Stop if `lsblk` shows anything other than the expected single XFS
partition** — that would mean this is not the machine that was inspected.

- [ ] **Step 3: Confirm the extra-files tree is intact**

```bash
ls -la /tmp/n100-nanoclaw-extra/etc/ssh/
stat -c '%a %n' /tmp/n100-nanoclaw-extra/etc/ssh/ssh_host_ed25519_key
```

Expected: both key files present, mode `600` on the private key.

- [ ] **Step 4: Run the install**

```bash
cd /home/nh/.config/nixos-config
just install-nanoclaw 10.0.60.51
```

Expected: disko partitions and formats, the system is installed, the host
reboots. Takes several minutes.

- [ ] **Step 5: Confirm it rebooted into the installed system**

```bash
ssh -o StrictHostKeyChecking=accept-new nh@10.0.60.51 \
  'hostname; uname -r; findmnt -no FSTYPE /'
```

Expected: `n100-nanoclaw`, a kernel version, and `ext4`. Logging in as
`nh` by key proves the inline user block and `authorizedKeys` are correct.

- [ ] **Step 6: Commit**

```bash
git add justfile
git commit -m "chore(justfile): add install-nanoclaw nixos-anywhere recipe"
```

---

### Task 5: Verify the platform end to end

Confirm every Phase A promise on the real machine, so Phase B starts from a known-good base.

**Files:**
- Create: `docs/superpowers/plans/2026-08-24-n100-nanoclaw-install-verification.md`

**Interfaces:**
- Consumes: the installed host from Task 4
- Produces: a verification record. Phase B assumes all six checks below pass.

- [ ] **Step 1: Verify agenix decrypted on first boot**

This is the whole point of `--extra-files`; if it failed, the host key was
not seeded and every secret is missing.

```bash
ssh nh@10.0.60.51 'sudo ls -la /run/agenix/n100-nanoclaw/'
ssh nh@10.0.60.51 'stat -c "%a %U %n" /home/nh/.config/hevy-mcp.env /home/nh/.ssh/id_obsidian'
```

Expected: **one** entry under `/run/agenix/n100-nanoclaw/` —
`telegram-bot-token.env`. The other two set an explicit `path`, so agenix
places them there instead of under `/run/agenix`, which is why they are
checked separately by the `stat` above. Both must be mode `400`, owner `nh`.
Three entries under `/run/agenix` would mean the `path` attributes were
dropped; zero entries means the host key was not seeded and `--extra-files`
failed.

- [ ] **Step 2: Verify Docker works as `nh` without sudo**

The `docker` group membership from the inline user block is what Phase B's
unit depends on.

```bash
ssh nh@10.0.60.51 'docker info --format "{{.ServerVersion}}"; docker run --rm hello-world'
```

Expected: a version string, then hello-world's success message.

- [ ] **Step 3: Verify the toolchain versions**

```bash
ssh nh@10.0.60.51 'node --version; pnpm --version; bun --version; claude --version'
```

Expected: `v22.x`, `11.x`, `1.3.x`, and a claude-code version. pnpm 11
against upstream's 10+ floor is the known watch point.

- [ ] **Step 4: Bring the host onto the tailnet**

There is no `tailscale-autoconnect` unit on this host and no authkey
secret, so this is a one-time interactive step.

```bash
ssh nh@10.0.60.51 'sudo tailscale up --ssh'
```

Follow the printed URL to authorise, then:

```bash
tailscale status | command grep n100-nanoclaw
```

Expected: the host appears on the tailnet from framework-13.

- [ ] **Step 5: Verify the firewall and SSH hardening**

```bash
ssh nh@10.0.60.51 'sudo iptables -S nixos-fw | command grep -E "22|tailscale0"'
ssh nh@10.0.60.51 'sudo sshd -T | command grep -iE "^permitrootlogin|^passwordauthentication"'
```

Expected: port 22 accepted and `tailscale0` trusted; `permitrootlogin no`
and `passwordauthentication no`.

- [ ] **Step 6: Verify a rebuild from framework-13 works**

Proves the host is maintainable the same way the rest of the fleet is.

```bash
cd /home/nh/.config/nixos-config
just deploy n100-nanoclaw
```

Expected: a successful `nixos-rebuild switch` against the remote host.

- [ ] **Step 7: Record the results and commit**

Write `docs/superpowers/plans/2026-08-24-n100-nanoclaw-install-verification.md`
with one line per check above, its command, and the actual observed output.
Note anything that needed a manual fix.

```bash
git add docs/superpowers/plans/2026-08-24-n100-nanoclaw-install-verification.md
git commit -m "docs(n100-nanoclaw): record platform verification results"
```

---

## Phase B preview (not this plan)

Written after Task 1's findings land. Expected shape:

1. Fork nanoclaw, clone to `/home/nh/nanoclaw`, bootstrap `nanoclaw.sh`, pair Telegram
2. `claude login` for the subscription OAuth
3. `systemd.services.nanoclaw` with `ConditionPathExists`, `EnvironmentFile`, `SupplementaryGroups=docker`
4. Agent image with `hevy-mcp` and `google-health-mcp-unofficial` baked in
5. Per-group `.mcp.json`, the persistent credentials volume, the `hevy-mcp.env` bind mount
6. Strava and Google Health OAuth via SSH port-forward
7. The vault sync wrapper (commit, pull `--rebase --autostash`, update, commit, push; conflict reports over Telegram)
8. Backups of the credentials volume and nanoclaw's SQLite state

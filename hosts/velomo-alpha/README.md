# velomo-alpha

Minimal NixOS server. Boots into Docker + [Komodo](https://komo.do) (Core + Periphery + MongoDB) — a GitOps deployer for `docker-compose` workloads stored in a private git repo. Everything beyond the bootstrap is added by editing the compose repo; no NixOS rebuild needed.

- **Spec:** [../../docs/superpowers/specs/2026-05-29-velomo-alpha-server-design.md](../../docs/superpowers/specs/2026-05-29-velomo-alpha-server-design.md)
- **Detailed plan:** [../../docs/superpowers/plans/2026-05-29-velomo-alpha-implementation.md](../../docs/superpowers/plans/2026-05-29-velomo-alpha-implementation.md)

This README is the quick-start. Use the plan as the full reference.

---

## Prerequisites

| Need | Detail |
|---|---|
| Hardware | Anything x86_64 with ≥4 GB RAM, an SSD/NVMe (1 disk is fine), wired Ethernet |
| Boot medium | NixOS minimal installer ISO on a USB stick |
| From framework-13 | This repo cloned + the `nix` CLI with flakes enabled (you already have this) |
| Tailscale | Reusable auth key from <https://login.tailscale.com/admin/settings/keys> |
| Compose repo | A private GitHub repo + a deploy token / fine-grained PAT with `contents: read` |

---

## Step 1 — Install the OS (`nixos-anywhere`)

Boot velomo-alpha from the NixOS minimal installer USB. On the installer console:

```bash
sudo passwd root                       # set a temporary root password
ip a                                   # note the IP, e.g. 192.168.1.42
lsblk                                  # confirm the install disk — adjust below if not /dev/nvme0n1
```

If `lsblk` shows the disk is not `/dev/nvme0n1`, edit [disko-config.nix](disko-config.nix) on framework-13 and commit.

From **framework-13**, in the nixos-config repo:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#velomo-alpha \
  --generate-hardware-config nixos-generate-config \
  ./hosts/velomo-alpha/hardware-configuration.nix \
  root@192.168.1.42
```

What this does:
1. SSHs into the installer, kexecs into a fresh NixOS installer environment.
2. Generates the real `hardware-configuration.nix` on the target and writes it back to this repo.
3. Runs disko (⚠️ **erases the disk**).
4. Builds the velomo-alpha closure and installs it.
5. Reboots.

Takes 5–20 minutes. When done, commit the generated hardware-config:

```bash
git add hosts/velomo-alpha/hardware-configuration.nix
git commit -m "feat(velomo-alpha): real hardware-configuration.nix from target"
git push
```

SSH in as `nh` to confirm:

```bash
ssh nh@192.168.1.42
hostname  # → velomo-alpha
```

---

## Step 2 — Wire the host into the secrets system

While SSH'd into velomo-alpha:

```bash
cat /etc/ssh/ssh_host_ed25519_key.pub
```

Copy that whole line. Back on **framework-13**, open [../../secrets/secrets.nix](../../secrets/secrets.nix) and add:

```nix
let
  framework-13 = "ssh-ed25519 AAAA... nick@hartj.es";
  framework-13-2 = "ssh-ed25519 AAAA... nick@hartj.es";
  velomo-alpha = "ssh-ed25519 AAAA<PASTE HOST KEY HERE>";   # ← new
  systems = [framework-13];
  velomoSystems = [velomo-alpha];                            # ← new
in {
  # ... existing entries unchanged ...

  # New entries for velomo-alpha:
  "velomo-alpha/komodo-passkey-env.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/komodo-core-env.age".publicKeys    = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/komodo-db.age".publicKeys          = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/tailscale-authkey.age".publicKeys  = [framework-13 framework-13-2] ++ velomoSystems;
}
```

---

## Step 3 — Create the four agenix secrets

From the repo root on framework-13:

```bash
mkdir -p secrets/velomo-alpha
cd secrets
```

Pick strong random values; `openssl rand -base64 32` is fine.

```bash
# Mongo + Komodo DB credentials. Same password used twice on purpose.
nix run github:ryantm/agenix -- -e velomo-alpha/komodo-db.age
```
Paste:
```
MONGO_INITDB_ROOT_USERNAME=komodo
MONGO_INITDB_ROOT_PASSWORD=<random>
KOMODO_DATABASE_USERNAME=komodo
KOMODO_DATABASE_PASSWORD=<same random>
```

```bash
nix run github:ryantm/agenix -- -e velomo-alpha/komodo-core-env.age
```
Paste:
```
KOMODO_PASSKEY=<random A>
KOMODO_JWT_SECRET=<random B>
```

```bash
nix run github:ryantm/agenix -- -e velomo-alpha/komodo-passkey-env.age
```
Paste — **the same** `KOMODO_PASSKEY` value you used above:
```
KOMODO_PASSKEY=<random A from previous file>
```

```bash
nix run github:ryantm/agenix -- -e velomo-alpha/tailscale-authkey.age
```
Paste only the auth key string from the Tailscale admin console (`tskey-auth-...`), no quotes, no trailing newline.

Verify and commit:

```bash
cd ..
ls secrets/velomo-alpha/
# → komodo-db.age, komodo-core-env.age, komodo-passkey-env.age, tailscale-authkey.age
git add secrets/secrets.nix secrets/velomo-alpha/
git commit -m "feat(velomo-alpha): agenix secrets for Komodo + Tailscale"
git push
```

---

## Step 4 — Activate secrets + Komodo on velomo-alpha

Edit [secrets.nix](secrets.nix) and replace its placeholder content with:

```nix
{config, ...}: {
  age.secrets = {
    "velomo-alpha/komodo-db"           = { file = ../../secrets/velomo-alpha/komodo-db.age;           owner = "root"; mode = "400"; };
    "velomo-alpha/komodo-core-env"     = { file = ../../secrets/velomo-alpha/komodo-core-env.age;     owner = "root"; mode = "400"; };
    "velomo-alpha/komodo-passkey-env"  = { file = ../../secrets/velomo-alpha/komodo-passkey-env.age;  owner = "root"; mode = "400"; };
    "velomo-alpha/tailscale-authkey"   = { file = ../../secrets/velomo-alpha/tailscale-authkey.age;   owner = "root"; mode = "400"; };
  };
}
```

Edit [default.nix](default.nix) to uncomment the deferred imports + docker toggle:

```nix
{
  pkgs, lib, inputs, outputs, config, ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./configuration.nix
    ../../components/nixos/system
    ../../components/nixos/hardware
    ../../components/nixos/virtualization
    inputs.home-manager.nixosModules.home-manager
    ./secrets.nix          # ← uncomment
    ./services             # ← uncomment
  ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs outputs;};
  };

  components.virtualization.docker.enable = true;   # ← uncomment
}
```

Add a Tailscale autoconnect oneshot to [configuration.nix](configuration.nix) (right below `services.tailscale.enable = true;`):

```nix
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

And add `jq` + `tailscale` to `environment.systemPackages` in the same file.

Commit, push, then on velomo-alpha:

```bash
sudo nix-shell -p git --run "git -C /tmp/nixos-config pull"
cd /tmp/nixos-config
sudo nixos-rebuild switch --flake .#velomo-alpha
```

Verify:

```bash
docker ps                    # 3 containers up: mongo, komodo-core, komodo-periphery
tailscale status             # this machine listed as velomo-alpha
curl -sI http://localhost:9120 | head -1   # HTTP/1.1 200 OK or 302
```

---

## Step 5 — Configure Komodo + deploy the first workload

From framework-13 (on Tailscale), browse to **<http://velomo-alpha:9120>**.

1. **Initial admin setup** — Komodo prompts on first visit.
2. **Servers** — the local Periphery should already be listed as Healthy (auto-onboarded via `KOMODO_FIRST_SERVER`).
3. **Git Provider** — Settings → Git Accounts. Paste your GitHub deploy token / PAT.
4. **Resource Sync** — point at your private compose repo, trigger a sync.
5. **First workload** — push a compose file for [Beszel](https://beszel.dev) (lightweight server monitoring) to the compose repo. Komodo deploys it. Browse to `http://velomo-alpha:8090` to confirm the dashboard.

Example `beszel.compose.yaml` to add to your compose repo:

```yaml
services:
  beszel-hub:
    image: henrygd/beszel:latest
    restart: unless-stopped
    ports: ["8090:8090"]
    volumes: ["./beszel_data:/beszel_data"]

  beszel-agent:
    image: henrygd/beszel-agent:latest
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./beszel_agent_data:/var/lib/beszel-agent
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      LISTEN: 45876
      KEY: "<paste public key from Beszel Hub UI after first start>"
```

You'll need to open TCP/8090 on `tailscale0` in [configuration.nix](configuration.nix) (or run Beszel behind a reverse proxy later):

```nix
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [9120 8090];
```

---

## Troubleshooting

### `nixos-anywhere` fails to kexec

Fall back to the manual ISO install: boot the installer on velomo-alpha, run disko + `nixos-install --flake .#velomo-alpha` from the console. Full steps in the plan's [Task 9 fallback section](../../docs/superpowers/plans/2026-05-29-velomo-alpha-implementation.md#fallback-manual-iso-install).

### Containers don't start after `nixos-rebuild switch`

```bash
systemctl status docker-mongo.service docker-komodo-core.service docker-komodo-periphery.service
journalctl -u docker-komodo-core.service -n 100
```

Most common cause: a missing env-file secret. Confirm `ls -la /run/agenix/` shows all four entries.

### Need to roll back

```bash
sudo nixos-rebuild switch --rollback
```

Or pick a previous generation from the systemd-boot menu at boot.

### Forgot the Komodo admin password

```bash
docker exec -it komodo-core /komodo-core --reset-admin
```

(Check the Komodo docs — the exact flag may change between versions.)

---

## What lives where

| File | Purpose |
|---|---|
| [default.nix](default.nix) | Host entry point — imports + component toggles |
| [configuration.nix](configuration.nix) | Base system: boot, network, SSH, inline `nh` user, firewall |
| [disko-config.nix](disko-config.nix) | Disk layout (single ext4 on `/dev/nvme0n1`) |
| [hardware-configuration.nix](hardware-configuration.nix) | Auto-generated on target by `nixos-generate-config` |
| [secrets.nix](secrets.nix) | agenix secret declarations (populated in Step 4) |
| [services/komodo.nix](services/komodo.nix) | The three oci-containers + network init |
| `/var/lib/komodo/{mongo,core,periphery}/` | Persistent state — **back this up** |
| `/opt/stacks/` | Where Komodo materializes compose files (regeneratable) |

---

## Explicitly NOT included

The design keeps the NixOS layer minimal. These are deliberately deferred to Komodo-managed workloads (or later design decisions):

- Reverse proxy (Caddy / Traefik)
- TLS termination for the Komodo UI (Tailscale handles transport encryption)
- Backups of `/var/lib/komodo/`
- fail2ban / automatic upgrades

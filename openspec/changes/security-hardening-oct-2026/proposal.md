## Why

The 2026-10-18 security scan, run after `a7042d6`, found that several hosts are still easy to get root on:

- n100-nanoclaw still accepts the old public password.
- velomo-alpha publishes unauthenticated Chrome DevTools and Postgres ports past the firewall.
- Tailscale SSH grants root on both servers.
- A full agent forward during deploys lets one compromised server reach the other.
- On framework-13, a YubiKey alone, a fingerprint alone, or the `docker` group is enough for root.

Each of these undercuts the hardening that `a7042d6` added, so they should be fixed before anything else lands.

## What Changes

**Remote access**
- Turn off Tailscale SSH on velomo-alpha and n100-nanoclaw (`--ssh=false`). sshd over the tailnet stays the only way in.
- **BREAKING:** the agent keys must be confirmed on every use (`AddKeysToAgent = confirm`, `ssh-add -c`), with an askpass dialog on framework-13. Every forwarded or local use of the keys, including `git push` and deploys, now shows a confirmation prompt.
- Drop nh from `docker` on velomo-alpha.
- Replace `@wheel` in `trusted-users` on the servers with closures signed on framework-13.
- Remove the stale `tailscale0.allowedTCPPorts` and stop trusting `tailscale0`. Open the needed ports explicitly instead.

**Network exposure**
- A firewall guard in Docker's `DOCKER-USER` chain drops new LAN connections to published container ports on every rootful Docker host, whatever the compose mapping says.
- Stop trusting the `br-+` interfaces.
- VMs: turn off SSH password and keyboard-interactive login.
- ISO configs: key-only SSH, no `nixos` password, no root password login.

**Secret handling**
- velomo-alpha secrets change from mode `0444` to `0440` with a dedicated `velomo-secrets` group.
- Correct the comments that claim `/run/agenix` is root-only.
- Remove the unused Authelia secrets.
- `secrets/justfile` uses the pinned `agenix` and a non-GUI editor. `nix run github:…` in justfiles goes through pinned flake inputs.
- Stop exporting the Grafana and Hevy tokens into every zsh session. Load them only for the MCP processes that use them.
- Remove the unused `authKey` string option from the tailscale component.

**Workstation authentication**
- `pam_u2f` reads a root-owned mapping file and requires the key's PIN.
- Fingerprint auth is off for sudo, polkit, su and run0.
- **BREAKING:** framework-13 moves to rootless Docker, and nh leaves the `docker` group.
- Drop nh from the `input` group.
- The idle and suspend lock falls back to swaylock if the shell lock IPC fails.
- framework-13 auto-upgrade tracks a protected `stable` branch.

**Shell supply chain**
- Replace antidote's runtime-fetched zsh plugins with nixpkgs packages.
- Drop `git-auto-fetch`.
- `myip` uses HTTPS.

**Cleanup**
- Remove the unused `pkgs/n8n-custom` and `pkgs/zellij-ps`.
- `agenix` follows nixpkgs.

**Manual (outside the repo)** — tracked in tasks so nothing is lost:
- Change the n100 password.
- Enable Secure Boot.
- Add passphrases to the agenix admin keys.
- Wipe VS Code history and rotate the leaked env secrets.
- Prune Claude Code auto-approvals.
- Make changes in the Dealdodo/scraper repo: compose ports, pgBackRest encryption, Logto admin exposure, oauth2-proxy group check, and pinning actions by SHA.

## Capabilities

### New Capabilities
- `remote-access`: how operators and deploys reach servers and get root (sshd, Tailscale SSH, agent use, Nix trust).
- `network-exposure`: which services hosts expose beyond loopback (Docker publishing, trusted interfaces, VM and ISO SSH).
- `secret-handling`: how agenix secrets are permissioned, edited and passed to the processes that use them.
- `workstation-auth`: what grants root or unlocks a session on framework-13 (PAM factors, privileged groups, screen lock, auto-upgrade source).

### Modified Capabilities
<!-- none: no existing specs -->

## Impact

- **Files:**
  - `hosts/velomo-alpha/{configuration,secrets}.nix`, `hosts/velomo-alpha/services/{doco,github-runner}.nix`
  - `hosts/n100-nanoclaw/configuration.nix`
  - `hosts/framework-13/{configuration,default}.nix`
  - `hosts/vm-{blackhawk,desktop}/configuration.nix`
  - `components/nixos/system/{yubikey,tailscale}.nix`, `components/nixos/virtualization/docker.nix`
  - `components/home-manager/cli/{ssh,zsh,fish}.nix`, `components/home-manager/features/desktop/{niri,mangowc}.nix`
  - `users/nh.nix`
  - `secrets/{secrets.nix,justfile}`, `justfile`, `flake.nix`, `pkgs/`, `installation/`
- **Workflow:**
  - Every SSH key use asks for confirmation.
  - Docker on the laptop runs rootless.
  - Deploys push signed closures.
  - Auto-upgrade only picks up commits pushed to `stable`.
- **Risk:** Rolling out PAM or sshd changes to a remote host can lock you out of it. See the migration plan in `design.md`.

## Context

See proposal.md (Why) for the findings. Constraints that shape the approach:

- **Mutable users:** `mutableUsers = true` everywhere, so password changes are made on the host and the repo can't fix them. Removing `initialHashedPassword` in `a7042d6` didn't change n100's live password.
- **Deploys:** `just deploy` copies closures as nh, then switches with `--elevate=sudo`. sudo authenticates through `security.pam.sshAgentAuth` against `/etc/ssh/authorized_keys.d/nh`, which holds the same two framework-13 keys used for login and GitHub.
- **velomo-alpha stacks:** doco-cd deploys these from the private Dealdodo repos. Port publishing in those compose files is outside this repo; a host-level Docker default is the only lever here.
- **agenix permissions:** agenix creates `/run/agenix.d` as `0751`, so a secret's own mode decides who can read it.
- **Runners:** the GitHub runners use `DynamicUser`, which is why the 444 secret modes were chosen. DynamicUser can't be a file owner, but it can take a static supplementary group.
- **Lock screens:** Noctalia's lock (niri) uses the `login` PAM stack. DMS (mango) uses its own PAM file.

## Goals / Non-Goals

**Goals:**
- Close every repo-side Critical, High and Medium finding.
- Keep `just deploy` a single command.
- Track each manual step as a task, so the findings outside the repo are not lost.

**Non-Goals:**
- Editing the Dealdodo/scraper or frontend repos. Those items are tracked only as follow-up tasks.
- Running nanoclaw as a separate user with rootless Docker on n100. That is its own change; for now n100 keeps nh in `docker`.
- Moving libvirt to `qemu:///session`. `libvirtd` membership stays an accepted risk on framework-13.
- Moving the agenix admin identity to the YubiKey. Passphrases on the keys are the step taken now.
- General kernel or sysctl hardening that the scan didn't flag.

## Decisions

### D1. Agent keys require confirmation on every use, not a separate deploy key
- `AddKeysToAgent = "confirm"`, `ssh-add -c` in the key-loading script, and an askpass program exported to `ssh-agent.service` as `SSH_ASKPASS`, with `SSH_ASKPASS_REQUIRE=force`.
- The askpass is `ksshaskpass`, which is already the system askpass (Plasma is enabled) and handles `SSH_ASKPASS_PROMPT=confirm` as a yes/no dialog. A wrapper reads `WAYLAND_DISPLAY` from `systemctl --user show-environment` when it runs, because the agent starts before the compositor exports it.
- The user chose this over a YubiKey-sk deploy key and over password-only deploys. It keeps today's deploy flow and makes every hijack attempt visible.
- `ForwardAgent=yes` stays in the justfile.
- **Trade-off:** each `git push`/`pull` over SSH, each ssh login and each sudo in a deploy prompts for confirmation. A server attacker who acts at the moment you expect a prompt can still get one approved. That residual risk is accepted.

### D2. Tailscale SSH off via `extraSetFlags`
- `services.tailscale.extraSetFlags = ["--ssh=false"]` on both servers, and `--ssh` is removed from velomo's autoconnect.
- `RunSSH` is stored in tailscaled's prefs, so removing `--ssh` from `up` alone wouldn't clear it. `extraSetFlags` runs `tailscale set` on every start.
- **Alternative:** a tailnet ACL that restricts `ssh`. Rejected because the policy lives outside the repo and is easy to drift from.

### D3. Signed closures replace `@wheel` trust
- framework-13 gets `nix.settings.secret-key-files` pointing at a key generated once (`nix key generate-secret`), stored at `/etc/nix/signing-key` (root `0400`, not in the repo).
- The servers add the public key to `trusted-public-keys` and set `trusted-users = ["root"]`.
- Locally built paths are then signed automatically. Paths copied from cache.nixos.org already carry its signature.
- **Alternative:** keep `@wheel`. Rejected because it makes nh root through `nix.conf` options.

### D4. DOCKER-USER guard in the shared component
- **Revised after the first deploy.** The original plan set `virtualisation.docker.daemon.settings.ip = "127.0.0.1"`. dockerd applies that only to the default `docker0` bridge. Compose networks ignore it, so velomo's scraper ports stayed on `0.0.0.0` after the deploy and a recreate. The setting stays for `docker0`, but it is not the guard.
- The guard lives in `components/nixos/virtualization/docker.nix`, through `networking.firewall.extraCommands` (`ip46tables`), on every rootful Docker host. In `DOCKER-USER` it returns for `ESTABLISHED,RELATED` and for traffic entering from `docker0`, `br+`, `lo` and `tailscale0`, and drops every other `NEW` connection. Docker evaluates `DOCKER-USER` first in FORWARD and never flushes it.
- **Alternatives:**
  - Per-network `com.docker.network.bridge.host_binding_ipv4` in each compose file: these live in other repos.
  - Binding in the compose files only (task 8.1): the clean fix, but outside this repo, and it doesn't protect future stacks.
- **Gap:** tailnet peers can still reach bare-published ports. That closes when 8.1 removes or loopback-binds those `ports:`.
- In the same file, `trustedInterfaces` drops `br-+` and keeps `docker0`, because `host.docker.internal` traffic needs it.
- Services that bind explicit IPs (Grafana on the tailnet IP, zot and beszel on loopback, OneCLI on `172.17.0.1`) are unaffected.
- **Risk:** anything meant to be LAN-reachable through a published port stops being reachable. Mitigation: compare `ss -tlnp` and LAN probes before and after. Nothing on velomo or n100 needs LAN access to a container.

### D5. Rootless Docker on framework-13 only
- framework-13 gets `virtualisation.docker.rootless = { enable = true; setSocketVariable = true; }` and `virtualisation.docker.enable = false`.
- The servers keep the rootful daemon, because doco-cd, the runners and pg-backup rely on it.
- The `docker` group in `users/nh.nix` already follows `virtualisation.docker.enable`, so it drops out automatically.
- Implementation: a `rootless` option on the docker component, which framework-13 sets.

### D6. Mode 0400 by default, `velomo-secrets` group only where needed
- Checked on the live host: doco-cd and zot run as uid 0 inside their containers. Compose `env_file`s are read by doco-cd, and the runner module copies `tokenFile` in a root `ExecStartPre` (`+`).
- So nearly every secret is `0400 root`. `alertmanager-slack-url` is `0400 nobody`, because the image runs as 65534.
- Only `frontend-build.env`, which the frontend runner's job step reads as its DynamicUser, uses `velomo-secrets` (gid 990) with mode 0440. The runners get the group through `SupplementaryGroups`.
- doco-cd needs no `--group-add`.

### D6a. Restart doco-cd after each agenix generation
- doco-cd bind-mounts `/run/agenix`, a symlink to `/run/agenix.d/<N>`. The mount pins generation N, and the next activation deletes it.
- An activation snippet ordered after `agenixChown` runs `systemctl --no-block try-restart docker-doco-cd`. It is a no-op at boot and when the unit is stopped.
- **Alternative:** mount `/run/agenix.d`. Rejected because compose files reference `/run/agenix/...` paths, which would then not exist inside the container.
- **Cost:** doco-cd restarts on every deploy. The stacks it manages keep running.

### D7. U2F: root-owned authfile plus PIN
- `security.pam.u2f.settings = { authfile = "/etc/u2f-mappings"; pinverification = 1; }`. The mapping line is public data (a key handle and a public key), so it can live in the repo through `environment.etc`.
- `control` stays `sufficient`, so losing the key never locks you out. With the PIN, the key is "have plus know".
- Fingerprint is disabled per service through `security.pam.services.<name>.fprintAuth = false` for `sudo`, `polkit-1`, `su` and `systemd-run0`. It stays on for login and lock.
- **Alternative:** `control = "required"`. Rejected because of the lockout risk.

### D8. Each MCP command sources its own token file
- The hevy MCP in the Obsidian vault already uses `sh -c '. ~/.config/hevy-mcp.env && exec npx -y hevy-mcp'`. The same one-line pattern replaces the global zsh `source`, so no wrapper scripts are needed.
- The grafana MCP is defined in Dealdodo/scraper's tracked `.mcp.json`, which needs the same change (task 8.6). Until that lands, the grafana MCP starts without a token.

### D9. zsh plugins from nixpkgs
- `programs.zsh.plugins` with `pkgs.zsh-autosuggestions`, `zsh-completions`, `zsh-powerlevel10k`, `zsh-fzf-tab` and `zsh-syntax-highlighting`.
- The OMZ plugins come from `pkgs.oh-my-zsh` through `programs.zsh.oh-my-zsh.plugins`, without `git-auto-fetch`.
- antidote is removed.

## Risks / Trade-offs

- **[sshd or PAM change locks out a remote host]**
  - Deploy servers with `nixos-rebuild test` first.
  - Keep a second SSH session open.
  - velomo has console access.
  - Never change PAM and sshd in the same deploy.
- **[Signed-closure switch breaks the next deploy]**
  - Add `trusted-public-keys` to the servers while `@wheel` is still trusted.
  - Deploy once and confirm signatures are accepted (`nix path-info --sigs` on the server).
  - Only then remove `@wheel`, in a second deploy.
- **[Rootless Docker breaks existing laptop workflows]** (privileged ports, `--network host` to host services, existing volumes):
  - Volumes don't migrate. Recreate dev databases.
  - This group of tasks is independent and can be reverted alone.
- **[Askpass doesn't show (no Wayland env in the user unit)]**
  - Pass `WAYLAND_DISPLAY` through `systemctl --user import-environment`, or set the service `Environment` explicitly.
  - Test with `ssh -T git@github.com` before relying on it for deploys.
- **[u2f PIN not set on the YubiKey]**
  - Set the FIDO2 PIN (`ykman fido access change-pin`) before deploying D7. Without a PIN, `pinverification` makes the key fail, and PAM falls through to the password, which is safe.

## Migration Plan

Order: manual emergency steps → network exposure → remote access (two-phase for D3) → secrets → workstation → cleanup. Each group is a separate commit and deploy, so `git revert` of one commit plus a redeploy rolls back that group. On framework-13, the previous generation in the boot menu is the fallback for PAM or Docker changes.

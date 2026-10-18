## 1. Manual emergency steps (operator, outside the repo)

- [x] 1.1 [manual] On n100-nanoclaw run `passwd nh`. Verify that `echo password | sudo -S -k true` fails and `passwd -S nh` shows today's date.
- [x] 1.2 [manual] Delete the VS Code Local History copies of decrypted secrets (`~/.config/Code/User/History/` entries for `*-app.env` and `observability.env`). Verify with `grep -rl 'SPRING_\|DATABASE_URL' ~/.config/Code/User/History | wc -l`, which should print 0.
- [ ] 1.3 [manual] Rotate the secrets in `frontend-app.env`, `logto-app.env`, `scraper-app.env` and `observability.env` at their providers. Re-encrypt them with `agenix -e`, deploy velomo-alpha, and verify the stacks come up healthy in doco-cd.
- [ ] 1.4 [manual] Add passphrases to `~/.ssh/id_ed25519` and `~/.ssh/id_framework-13_2025-06-07` (`ssh-keygen -p -f …`). Verify that `ssh-keygen -y -P '' -f <key>` fails for both.
- [ ] 1.5 [manual] Prune Claude Code auto-approvals: remove `Bash(nix run *)`, `Bash(find:*)` and `Bash(gh api:*)` from `.claude/settings.local.json`, and `Bash(curl:*)` from `~/.claude/settings.json`. Verify by grepping both files.
- [ ] 1.6 [manual] Set a FIDO2 PIN on the YubiKey (`ykman fido access change-pin`). Verify `ykman fido info` reports that a PIN is set. This is needed before group 6.

## 2. Network exposure

- [x] 2.1 Before changing anything, capture `ss -tlnp` from velomo-alpha and n100-nanoclaw into the scratchpad, so the listeners can be compared after 2.3.
- [x] 2.2 In `components/nixos/virtualization/docker.nix`, add the DOCKER-USER guard (design D4, revised), keep `daemon.settings.ip` for `docker0` only, and change `trustedInterfaces` to `["docker0"]`. Verify that the rules load for IPv4 and IPv6 in a scratch netns and that all hosts build.
- [x] 2.3 Deploy velomo-alpha and n100-nanoclaw, then recreate the published containers (`docker compose up -d --force-recreate` through doco-cd, or by restarting the stack). Verify that `iptables -S DOCKER-USER` on both servers shows the guard, that `curl -m3 http://10.0.60.132:9222/json/version` and connections to 7700, 3001 and 5432 from framework-13 over the LAN time out, and that Grafana on the tailnet IP still answers. Verify the public sites behind the Cloudflare tunnel still load.
- [x] 2.4 In `hosts/vm-blackhawk/configuration.nix` and `hosts/vm-desktop/configuration.nix`, set `PasswordAuthentication = false` and `KbdInteractiveAuthentication = false`. Verify with `nix eval` of `services.openssh.settings` for both.
- [x] 2.5 In `installation/iso-custom/configuration.nix` and `installation/iso-minimal/flake.nix`:
  - Remove `initialPassword`.
  - Add the two framework-13 public keys to `users.users.nixos.openssh.authorizedKeys.keys`.
  - Set `PasswordAuthentication = false` and `PermitRootLogin = "prohibit-password"`.
  - Verify by grepping for `initialPassword` (none) and running `nix eval` in `iso-minimal`. Restore the `flake.lock` afterwards if it was relocked.

## 3. Remote access

- [x] 3.1 On both servers, set `services.tailscale.extraSetFlags = ["--ssh=false"]` and remove `--ssh` from velomo-alpha's `tailscale-autoconnect` (`hosts/velomo-alpha/configuration.nix:83`). Deploy, then verify `tailscale debug prefs | jq .RunSSH` returns `false` and `tailscale ssh nh@velomo-alpha` is refused.
- [x] 3.2 On both servers, replace `trustedInterfaces = ["tailscale0"]` with `interfaces.tailscale0.allowedTCPPorts` set to the ports that are actually used: 22, plus 3300 for Grafana on velomo. Use the 2.1 `ss` capture to check nothing else is needed. Remove the stale `[9120 8080 8090]`. Deploy, then verify that SSH and Grafana over the tailnet still work and that `tailscale0` is no longer in the effective `trustedInterfaces`. Container ports published without an IP stay reachable from the tailnet (the DOCKER-USER guard returns for `tailscale0`) until task 8.1 lands.
- [x] 3.3 Remove `"docker"` from nh's `extraGroups` on velomo-alpha (`hosts/velomo-alpha/configuration.nix:115`). On n100-nanoclaw, keep it and add a comment explaining it as a documented exception (nanoclaw runs as nh), and fix the wrong "agents can't sudo" comments on both hosts. Verify that `id nh` on velomo has no `docker` after deploying and re-logging in.
- [x] 3.4 In `components/home-manager/cli/ssh.nix`:
  - Set `AddKeysToAgent = "confirm"`, and use `ssh-add -c` in `loadKeysScript`.
  - Add `lxqt.lxqt-openssh-askpass` to packages, and export `SSH_ASKPASS` and `SSH_ASKPASS_REQUIRE=force` to the `ssh-agent` user service, including the Wayland env.
  - Verify: after logging in, `ssh-add -l` lists both keys, and `ssh -T git@github.com` pops a confirmation dialog. Declining it makes authentication fail.
- [x] 3.5 Run `just deploy n100-nanoclaw` and verify that the sudo step on the server triggers the confirmation dialog on framework-13 and that the deploy completes after approval.
- [x] 3.6 Generate the Nix signing key on framework-13 (`sudo sh -c 'umask 077; nix key generate-secret --key-name framework-13-1 > /etc/nix/signing-key'`) and set `nix.settings.secret-key-files` in `hosts/framework-13/configuration.nix`. Sign the store paths that already exist once with `sudo nix store sign --all --key-file /etc/nix/signing-key`; paths built before the key existed are unsigned and would be rejected after 3.7. Add the public key to `nix.settings.trusted-public-keys` on both servers, keeping `@wheel` for now. Deploy, then verify with `nix path-info --sigs` that a freshly deployed system path on the server shows `framework-13-1:` among its signatures.
- [x] 3.7 Remove `"@wheel"` from `trusted-users` on both servers (`hosts/velomo-alpha/configuration.nix:31`, `hosts/n100-nanoclaw/configuration.nix:49`) and update their comments. Deploy each server, then do a no-op deploy afterwards to confirm the signed-closure path works. Verify that `nix config show trusted-users` on the servers returns `root`.

## 4. Secret handling

- [x] 4.1 Tighten the secret modes in `hosts/velomo-alpha/secrets.nix` per design D6:
  - Use `0400 root` for nearly all secrets, `0400 nobody` for `alertmanager-slack-url`, and `velomo-secrets` (gid 990, `0440`) only for `frontend-build.env`.
  - Fix the "root-only directory" comments.
  - Verify that `nix eval` shows no secret with mode `0444`.
- [x] 4.2 Grant `velomo-secrets` to the frontend runner (`SupplementaryGroups` in `services/github-runner.nix`; done in code). doco-cd runs as root, so it needs no group. Deploy, then verify that `sudo -u nobody cat /run/agenix/velomo-alpha/scraper-app.env` fails, that the runners register and stay online, and that a doco-cd redeploy of the scraper stack succeeds.
- [x] 4.3 Remove `authelia-secrets.env` and `authelia-users.yml` from `hosts/velomo-alpha/secrets.nix` and `secrets/secrets.nix`, and `git rm` their `.age` files. Verify that `/run/agenix` on velomo has no `authelia*` after deploying.
- [x] 4.4 In `secrets/justfile`:
  - Replace `nix run github:ryantm/agenix` with the pinned `agenix` from user packages.
  - Set `EDITOR := "nvim"` (or pipe through stdin, per the agenix memory note).
  - Verify by running `just` in `secrets/` with a dry-run edit of a test secret, and checking that no GitHub fetch appears.
- [x] 4.5 In the root `justfile`, replace `nix run github:astro/deadnix`, `github:kamadorueda/alejandra`, `disko/latest` and `github:nix-community/nixos-anywhere` with pinned sources: `nixpkgs#…` or devShell packages, and `inputs.disko` for disko. Verify that `just --dry-run <recipe>` shows no unpinned `github:` refs.
- [ ] 4.6 Remove the global token `source` lines from `users/nh.nix` (done in code; hevy's `.mcp.json` already sources its own file, see D8). After task 8.6 and a rebuild, Verify that a new zsh shows neither token in `env` and that both MCP servers still connect in Claude Code.
- [x] 4.7 In `components/nixos/system/tailscale.nix`, delete the unused `authKey` string option. Verify that `nix flake check` (or evaluating all hosts) still succeeds.

- [x] 4.8 Add a velomo-alpha activation step (`services/doco.nix`), ordered after `agenixChown`, that runs `systemctl --no-block try-restart docker-doco-cd`. doco-cd's `/run/agenix` bind mount pins the agenix generation that existed when it started, so every activation broke deploys ("couldn't find env file"; broken since 16:42 on 2026-10-18 until a manual restart). Verify that after `just deploy velomo-alpha`, the doco-cd journal shows a fresh start and the next poll has no env-file errors.

## 5. Workstation: rootless Docker

- [x] 5.1 Add a `rootless` option to `components/nixos/virtualization/docker.nix`. When it is set, enable `virtualisation.docker.rootless = { enable = true; setSocketVariable = true; }` and set `virtualisation.docker.enable = false`. Enable the option in `hosts/framework-13/default.nix`. Verify that `nix eval` shows `docker.enable = false` and `rootless.enable = true` for framework-13, and leaves the servers unchanged.
- [x] 5.2 Rebuild framework-13 and log out and back in. Verify that `id nh` has no `docker`, `docker run --rm hello-world` works, and `docker run --rm -v /:/h alpine touch /h/root/x` fails.

## 6. Workstation authentication and locking

- [ ] 6.1 Generate the u2f mapping with `pamu2fcfg -u nh`, and add it to the repo as `environment.etc."u2f-mappings"`. The mapping contains only public data. Set `security.pam.u2f.settings.authfile = "/etc/u2f-mappings"` and `pinverification = 1` in `components/nixos/system/yubikey.nix`. Rebuild while a root shell stays open, then verify:
  - sudo with key plus PIN works.
  - sudo with a key whose mapping is only in `~/.config/Yubico/u2f_keys` falls through to the password.
- [x] 6.2 Set `security.pam.services.{sudo,polkit-1,su,systemd-run0}.fprintAuth = false` on framework-13. Verify that `/etc/pam.d/sudo` has no `pam_fprintd` line and that `/etc/pam.d/login` still has it.
- [x] 6.3 Remove `"input"` from nh's `extraGroups` (`users/nh.nix:32`). Verify after rebuilding and re-logging in that `id nh` lacks `input` and that niri, mango and gaming input still work.
- [x] 6.4 Make the idle and before-sleep lock commands in `features/desktop/niri.nix` and `mangowc.nix` run `<shell lock> || swaylock -f`, and make sure `security.pam.services.swaylock` exists. Verify by killing the shell, triggering the lock with `loginctl lock-session`, or waiting for the idle timeout, and checking that swaylock appears.
- [ ] 6.5 Create a `stable` branch on GitHub, and protect it against force pushes and deletion. Set `system.autoUpgrade.flake = "github:nickhartjes/nixos-config/stable"`. Verify with `nix eval` of `system.autoUpgrade.flags` and `gh api repos/nickhartjes/nixos-config/branches/stable/protection`.
- [ ] 6.6 [manual] Enroll Secure Boot keys (`sudo sbctl enroll-keys --microsoft`), enable Secure Boot in the Framework BIOS, and set a BIOS supervisor password. Verify that `bootctl status` reports `Secure Boot: enabled (user)`.
- [ ] 6.7 [manual] Run `sudo cryptsetup luksDump /dev/nvme0n1p2`. Confirm the FIDO2 token has `fido2-clientPin-required: true` and that a passphrase keyslot exists as recovery. If not, re-enroll with `systemd-cryptenroll --fido2-with-client-pin=yes`.

## 7. Shell supply chain and cleanup

- [x] 7.1 Replace antidote in `components/home-manager/cli/zsh.nix` with `programs.zsh.plugins` from nixpkgs, and with `programs.zsh.oh-my-zsh.plugins` (the existing OMZ list minus `git-auto-fetch`). Keep `.p10k.zsh` loading. Verify that a new shell shows the p10k prompt and autosuggestions, and that `~/.cache/antidote` is no longer refreshed.
- [x] 7.2 Change `myip` to `https://ifconfig.me` in `cli/zsh.nix` and `cli/fish.nix`. Verify by running `myip`.
- [x] 7.3 Delete `pkgs/n8n-custom` and `pkgs/zellij-ps`, and remove their commented entries in `pkgs/default.nix`. Verify that every host still evaluates.
- [x] 7.4 Add `inputs.nixpkgs.follows = "nixpkgs"` to the `agenix` input in `flake.nix`, then run `nix flake lock`. Verify that `nix flake metadata` shows agenix without its own nixpkgs, and that all hosts build (`nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run`).

## 8. External follow-ups (Dealdodo repos, tracked only)

- [ ] 8.1 [manual] In Dealdodo/scraper, move `ports:` for the db, meilisearch, browserless and chrome services out of the prod compose (`!reset []`), and set a browserless `TOKEN`. Verify that the doco-cd deploy succeeds and `ss` still shows only loopback.
- [ ] 8.2 [manual] Set `repo1-cipher-type=aes-256-cbc` with the passphrase from a new agenix secret in the pgBackRest templates. Verify with a new stanza and a successful `pgbackrest check`, and keep an offline copy of the passphrase.
- [ ] 8.3 [manual] Restrict `auth-admin.velomo.cc` to the tailnet or Cloudflare Access. Verify that it is unreachable from a non-tailnet network.
- [ ] 8.4 [manual] Check that oauth2-proxy sets `OAUTH2_PROXY_ALLOWED_GROUPS` and whether Logto public sign-up is enabled. Verify that a non-admin Logto account is denied at admin.velomo.cc.
- [ ] 8.5 [manual] Pin the self-hosted workflow actions to commit SHAs, and pin beszel-agent to a version or digest. Verify that the next tagged release builds.
- [ ] 8.6 [manual] In Dealdodo/scraper's `.mcp.json`, change the grafana server to `"command": "sh", "args": ["-c", ". \"$HOME/.config/velomo-grafana-sa.env\" 2>/dev/null; GRAFANA_SERVICE_ACCOUNT_TOKEN=\"$GRAFANA_SA_TOKEN\" exec mise exec -- mcp-grafana -transport stdio"]` and drop the token from `env`. Verify that the grafana MCP connects in Claude Code from a shell without the token exported.

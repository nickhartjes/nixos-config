# n100-nanoclaw install verification (Task 5)

Date: 2026-08-24, run against `nh@10.0.60.51` (hostname `n100-nanoclaw`), repo at commit
`a216434bdb91163a6fe5207615f972c1c275d3a6` on `main`, working tree clean.

Starting state (checked immediately before this run): installed and booting from disk,
no USB present, uptime ~155s after a clean reboot; partitions match disko exactly
(`nvme0n1p1` 1M, `nvme0n1p2` 512M `/boot`, `nvme0n1p3` 476.4G ext4 `/`); kernel `6.18.45`.

## Step 1: agenix decrypted on first boot — PASS (with a correction to the plan's assumption)

Commands run:

```
ssh nh@10.0.60.51 'sudo ls -la /run/agenix/n100-nanoclaw/'
ssh nh@10.0.60.51 'stat -c "%a %U %n" /home/nh/.config/hevy-mcp.env /home/nh/.ssh/id_obsidian'
```

The `sudo` form of the first command failed:

```
sudo: a terminal is required to read the password; either use ssh's -t option or configure an askpass helper
sudo: a password is required
```

(root cause: `hosts/n100-nanoclaw/configuration.nix` sets no `security.sudo.extraConfig`
NOPASSWD rule for `nh`, unlike `framework-13`, `vm-blackhawk`, `vm-desktop` — see the
cross-cutting note at the bottom.) The directory itself is world-readable, so the same
listing without `sudo` succeeded:

```
$ ssh nh@10.0.60.51 'ls -la /run/agenix/n100-nanoclaw/; ls -ld /run/agenix /run/agenix/n100-nanoclaw'
total 12
drwxr-xr-x 2 root root    0 Aug 24 12:17 .
drwxr-x--x 3 root keys    0 Aug 24 12:17 ..
-r-------- 1 nh   users  57 Aug 24 12:17 hevy-api-key
-r-------- 1 nh   users 419 Aug 24 12:17 obsidian-deploy-key
-r-------- 1 root root   66 Aug 24 12:17 telegram-bot-token.env
lrwxrwxrwx 1 root root 15 Aug 24 12:17 /run/agenix -> /run/agenix.d/1
drwxr-xr-x 2 root root  0 Aug 24 12:17 /run/agenix/n100-nanoclaw
```

This shows **three** real files, not the one the brief predicted. Reading the two
path-declaring secrets:

```
$ ssh nh@10.0.60.51 'ls -la /home/nh/.config/hevy-mcp.env /home/nh/.ssh/id_obsidian'
lrwxrwxrwx 1 root root 38 Aug 24 12:17 /home/nh/.config/hevy-mcp.env -> /run/agenix/n100-nanoclaw/hevy-api-key
lrwxrwxrwx 1 root root 45 Aug 24 12:17 /home/nh/.ssh/id_obsidian -> /run/agenix/n100-nanoclaw/obsidian-deploy-key
```

They are **symlinks** into `/run/agenix/n100-nanoclaw/`, not separate files — `stat`
without `-L` reports the symlink's own inode (mode `777`, owner `root`), which is why
the brief's literal `stat -c "%a %U %n"` command (no `-L`) returned `777 root` for both,
not `400 nh`. Following the link with `stat -L` gives the real target:

```
$ ssh nh@10.0.60.51 'stat -L -c "%a %U %G %n" /home/nh/.config/hevy-mcp.env /home/nh/.ssh/id_obsidian'
400 nh users /home/nh/.config/hevy-mcp.env
400 nh users /home/nh/.ssh/id_obsidian
```

Byte counts (no content read):

```
$ ssh nh@10.0.60.51 'wc -c /home/nh/.config/hevy-mcp.env /home/nh/.ssh/id_obsidian'
 57 /home/nh/.config/hevy-mcp.env
419 /home/nh/.ssh/id_obsidian
476 total
```

**Verdict: PASS.** All three secrets decrypted on first boot — the host key was
correctly seeded by `--extra-files`. The brief's specific prediction ("only one entry
under `/run/agenix`, three would mean `path` was dropped") is incorrect as a diagnostic:
agenix's `path` option creates a symlink at that path pointing back into
`/run/agenix/<host>/<name>`, it does not relocate the decrypted file out of
`/run/agenix`. Effective permissions are exactly as required: both path-declared
secrets resolve (via their symlink) to mode `400`, owner `nh`, group `users`, with
non-zero byte counts; the third secret (`telegram-bot-token.env`, no explicit path)
sits at `/run/agenix/n100-nanoclaw/telegram-bot-token.env`, mode `400`, owner `root`,
66 bytes, matching the unit that consumes it. No secret content was read.

## Step 2: Docker works for `nh` without sudo — PASS

```
$ ssh nh@10.0.60.51 'docker info --format "{{.ServerVersion}}"; docker run --rm hello-world'
29.7.2
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
...
Hello from Docker!
This message shows that your installation appears to be working correctly.
...
```

**Verdict: PASS.** Version string printed, image pulled and ran, hello-world success
message printed. No `sudo` was used or needed.

## Step 3: Toolchain versions — PASS

```
$ ssh nh@10.0.60.51 'node --version; pnpm --version; bun --version; claude --version'
v22.23.2
11.21.0
1.3.13
2.1.238 (Claude Code)
```

**Verdict: PASS.** All four tools resolve and report versions.

## Step 4: Tailscale — BLOCKED, not merely pending

Attempted per the brief (detached, to capture the auth URL without blocking):

```
$ ssh nh@10.0.60.51 'sudo sh -c "nohup tailscale up --ssh > /tmp/tsup.log 2>&1 &"; sleep 6; cat /tmp/tsup.log'
sudo: a terminal is required to read the password; either use ssh's -t option or configure an askpass helper
sudo: a password is required
cat: /tmp/tsup.log: No such file or directory
```

**Verdict: FAIL / blocked — no auth URL obtained.** The outer `sudo` itself was
rejected before `tailscale up` ever ran, so no log file was created and no auth URL
exists to hand to a human. This is not "pending human authorisation" as anticipated —
`tailscale up` never started. Root cause is the same sudo-password gap as Steps 5 and
6 (see note below). This needs someone with the console/sudo password to run
`sudo tailscale up --ssh` interactively.

## Step 5: Firewall / SSH hardening — BLOCKED

```
$ ssh nh@10.0.60.51 'sudo iptables -S nixos-fw | command grep -E "22|tailscale0"'
sudo: a terminal is required to read the password; either use ssh's -t option or configure an askpass helper
sudo: a password is required

$ ssh nh@10.0.60.51 'sudo sshd -T | command grep -iE "^permitrootlogin|^passwordauthentication"'
sudo: a terminal is required to read the password; either use ssh's -t option or configure an askpass helper
sudo: a password is required
```

Confirmed there is no non-root fallback (both genuinely require root):

```
$ ssh nh@10.0.60.51 'iptables -S nixos-fw'
iptables v1.8.13 (nf_tables): Could not fetch rule set generation id: Permission denied (you must be root)

$ ssh nh@10.0.60.51 'sshd -T'
Unable to load host key: /etc/ssh/ssh_host_rsa_key
Unable to load host key: /etc/ssh/ssh_host_ed25519_key
sshd: no hostkeys available -- exiting.
```

**Verdict: FAIL / blocked — not verified.** Could not confirm the `tailscale0`-trusted
firewall rule or `PermitRootLogin no` / `PasswordAuthentication no` sshd settings.
Given `firewall.trustedInterfaces = ["tailscale0"]` and the fleet's usual sshd hardening
module are present in the Nix source, this is very likely fine in practice, but it was
not empirically confirmed on the running host, and the check is reported as failed per
instructions rather than assumed.

## Step 6: Remote rebuild — FAIL

```
$ nixos-rebuild switch --flake .#n100-nanoclaw --target-host nh@10.0.60.51 --use-remote-sudo
nixos-rebuild: warning: --use-remote-sudo is deprecated, use --elevate=sudo instead
building the system configuration...
...
copying path '/nix/store/vpvx4h96bq9pxw0fm4w4nhwhxrb5yz2n-nixos-system-n100-nanoclaw-26.11.20260822.2c423e0' to 'ssh://nh@10.0.60.51'...

We trust you have received the usual lecture from the local System Administrator...
sudo: a terminal is required to read the password; either use ssh's -t option or configure an askpass helper
sudo: a password is required
error: while running command with remote sudo, did you forget to use --ask-elevate-password?
Command 'ssh ... nh@10.0.60.51 -- sudo /bin/sh -c '"'"'exec /usr/bin/env -i PATH="${PATH-}" "$@"'"'"'' sh nix-env -p /nix/var/nix/profiles/system --set /nix/store/vpvx4h96bq9pxw0fm4w4nhwhxrb5yz2n-nixos-system-n100-nanoclaw-26.11.20260822.2c423e0' returned non-zero exit status 1.
```

**Verdict: FAIL.** The build succeeded locally and the closure copied to the remote
host without issue, but activation (`nix-env --set` via remote `sudo`) was rejected
for the same reason as Steps 4 and 5. The host was **not** switched to the new
generation; it remains on whatever generation was active from the original install.
No workaround was applied.

## Cross-cutting root cause for the three failures

`hosts/n100-nanoclaw/configuration.nix` does not grant `nh` passwordless sudo. Compare:

```
hosts/framework-13/configuration.nix:237:  security.sudo.extraConfig = "nh ALL=(ALL) NOPASSWD: ALL";
hosts/vm-blackhawk/configuration.nix:88:   security.sudo.extraConfig = "nixos ALL=(ALL) NOPASSWD: ALL";
hosts/vm-desktop/configuration.nix:80:     security.sudo.extraConfig = "nixos ALL=(ALL) NOPASSWD: ALL";
```

`n100-nanoclaw` has no equivalent line, and `sudo -n true` on the host confirms there is
no cached ticket and no NOPASSWD rule:

```
$ ssh nh@10.0.60.51 'sudo -n true'
sudo: a password is required
```

This blocks unattended remote administration of this host, including the required
`--use-remote-sudo` rebuild path. It needs either a human with the console/sudo
password to run Steps 4–6 interactively, or a deliberate decision (out of scope for
this read-mostly verification task) to add a NOPASSWD rule matching the rest of the
fleet.

## Summary

| Step | Check | Result |
|---|---|---|
| 1 | agenix decrypted on first boot | PASS |
| 2 | Docker works for `nh` without sudo | PASS |
| 3 | Toolchain versions | PASS |
| 4 | Tailscale `up --ssh` | FAIL / blocked (no sudo password) |
| 5 | Firewall + sshd hardening | FAIL / blocked (no sudo password) |
| 6 | Remote rebuild via `--use-remote-sudo` | FAIL (no sudo password) |

Phase B should not assume Steps 4–6 are done. The host needs an operator with its sudo
password to join the tailnet, and until then `nixos-rebuild ... --use-remote-sudo`
cannot switch this host at all — the fleet's day-to-day `just deploy n100-nanoclaw`
path is unusable until this is resolved.

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

## Step 4: Tailscale — PASS

The original attempt (detached `sudo tailscale up --ssh` run directly on the host) was
blocked by the same sudo-password gate described below. Re-verified instead from
`framework-13`, against the tailnet:

```
$ tailscale status | grep n100-nanoclaw
100.101.27.10    n100-nanoclaw    nickhartjes@  linux    -
$ tailscale ip -4 n100-nanoclaw
100.101.27.10
$ getent hosts n100-nanoclaw
100.101.27.10   n100-nanoclaw.barking-morpho.ts.net
```

**Verdict: PASS.** The host is joined to the tailnet, has a stable tailnet IP, and
resolves via MagicDNS. Tailscale SSH is also active: an SSH attempt over the tailnet
was intercepted by Tailscale's check-mode policy, which is `--ssh` behaving exactly as
intended (interactive authorisation, not a failure). The interactive authorisation was
carried out by the user.

## Step 5: Firewall / SSH hardening — PASS

The original attempt (`sudo iptables -S` / `sudo sshd -T` over SSH) was blocked by the
same sudo-password gate described below. Re-verified interactively on the host console
by the user:

```
-A nixos-fw -i tailscale0 -j nixos-fw-accept
-A nixos-fw -p tcp -m tcp --dport 22 -j nixos-fw-accept
PermitRootLogin no
PasswordAuthentication no
```

**Verdict: PASS.** The `tailscale0`-trusted firewall rule and the fleet's usual sshd
hardening (`PermitRootLogin no`, `PasswordAuthentication no`) are both active on the
running host, matching the Nix source.

## Step 6: Remote rebuild — PARTIAL

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

**Verdict: PARTIAL, not failed.** Flake evaluation and the closure copy to the remote
host both succeeded without issue. Only the final activation step
(`nix-env --set` via remote `sudo`) stopped, because it needs an interactive sudo
password. The host was **not yet** switched to the new generation; it remains on
whatever generation was active from the original install. This is awaiting one
interactive run (`just deploy n100-nanoclaw`, which already carries
`--ask-sudo-password` — see below), not a fix.

## Sudo policy: deliberate parity with `velomo-alpha`, not a defect

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

A fleet audit shows this is intentional, not an oversight: `framework-13`,
`m3-kratos`, `vm-blackhawk` and `vm-desktop` set
`security.sudo.wheelNeedsPassword = false` (workstations/VMs, always at a keyboard),
while `velomo-alpha` — the only other headless server in the fleet — deliberately does
**not**, and `justfile`'s `deploy` recipe carries `--ask-sudo-password` for exactly
that case. `n100-nanoclaw` matching `velomo-alpha`'s policy is correct parity for a
headless server, not a defect. No change was made to this host's sudo policy as part
of this verification.

This does mean Steps 4–6 could not be driven unattended over plain SSH from this task;
Steps 4 and 5 were instead confirmed via the tailnet and an interactive console session
respectively, and Step 6 still needs one interactive `--ask-sudo-password` run to
complete activation.

## Summary

| Step | Check | Result |
|---|---|---|
| 1 | agenix decrypted on first boot | PASS |
| 2 | Docker works for `nh` without sudo | PASS |
| 3 | Toolchain versions | PASS |
| 4 | Tailscale `up --ssh` | PASS |
| 5 | Firewall + sshd hardening | PASS |
| 6 | Remote rebuild via `--use-remote-sudo` | PARTIAL — awaiting one interactive activation run |

Phase B can proceed: Steps 1–5 are fully confirmed. Step 6 only needs one interactive
`just deploy n100-nanoclaw` run (it already carries `--ask-sudo-password`) to switch
the host to the latest generation — the fleet's day-to-day deploy path is expected to
work exactly as it does for `velomo-alpha`.

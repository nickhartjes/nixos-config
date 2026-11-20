# T3 server on velomo-alpha

The host imports the shared T3 Home Manager module for `nh`. It installs T3,
Codex, Claude Code, GitHub CLI and ripgrep. The user service starts at boot
with lingering enabled and listens on `127.0.0.1:3773`.

Deploy from the Framework:

```sh
just deploy velomo-alpha --target-host nh@velomo-alpha
```

Inspect over SSH:

```sh
ssh nh@velomo-alpha
systemctl --user status t3code
journalctl --user -u t3code -n 50
```

For T3 Connect, authorize this host once as `nh`:

```sh
t3 connect link --headless
systemctl --user restart t3code
t3 connect status
```

Follow the CLI's browser login instructions using your T3 account. Provider
credentials must also be configured on this host. Keep credentials out of Nix.
Do not use `t3 up`, `t3 service install`, or `t3 update`: Nix manages the service
and version. Data is stored under `/home/nh/.t3` and is not automatically backed
up by the existing production database backup jobs.

An SSH port forward also provides local browser access:

```sh
ssh -L 3774:127.0.0.1:3773 nh@velomo-alpha
```

Run `t3 pair` on Velomo to obtain a pairing code. In the desktop client's
Remote link form, use `http://127.0.0.1:3774` and that code while the SSH tunnel
is running. Forwarding makes the remote service reachable without opening a
new firewall port.

`nh` retains its existing permissions: it is not added to the Docker group.

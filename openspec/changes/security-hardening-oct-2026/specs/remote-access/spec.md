## Purpose

Defines how operators and deploys reach the servers (velomo-alpha, n100-nanoclaw) and gain root, so that root always requires an authenticated sshd session plus an explicit, confirmed use of an operator key.

## ADDED Requirements

### Requirement: No Tailscale SSH on servers
Servers SHALL NOT accept Tailscale SSH sessions. Remote shell access SHALL go only through sshd, which enforces `PermitRootLogin = no` and key-only authentication.

#### Scenario: Tailscale SSH refused
- **WHEN** a tailnet node runs `tailscale ssh root@velomo-alpha` or `tailscale ssh nh@n100-nanoclaw`
- **THEN** the connection is refused, and `tailscale debug prefs` on the server shows `RunSSH: false`

#### Scenario: Setting survives re-authentication
- **WHEN** tailscaled restarts or the node re-authenticates
- **THEN** `RunSSH` stays false, because the declarative config sets it on every start

### Requirement: Operator keys require confirmation per use
On framework-13, the SSH keys that are authorized on servers or GitHub SHALL be loaded into the agent with per-use confirmation. Every signing request, local or forwarded, SHALL show a confirmation dialog before the agent signs.

#### Scenario: Forwarded agent used from a server
- **WHEN** a process on a server uses the forwarded agent socket (for sudo via sshAgentAuth, or to ssh onward)
- **THEN** framework-13 shows a confirmation dialog, and the signature is refused if the dialog is declined or dismissed

#### Scenario: Keys loaded at login
- **WHEN** the session starts and the key-loading service runs
- **THEN** `ssh-add -l` lists both keys, and each use of them prompts for confirmation

### Requirement: Servers grant root only through sudo
On velomo-alpha, nh SHALL NOT be in any group that grants root without sudo (`docker`). n100-nanoclaw MAY keep nh in `docker` until nanoclaw runs as its own user, and that exception SHALL be documented in its configuration.

#### Scenario: Docker socket on velomo-alpha
- **WHEN** nh runs `docker ps` on velomo-alpha without sudo
- **THEN** it fails with permission denied on `/var/run/docker.sock`

### Requirement: Servers accept only signed store paths from non-root users
Server Nix daemons SHALL NOT list `@wheel` in `trusted-users`. Deploys SHALL copy closures signed with a framework-13 key that the servers list in `trusted-public-keys`.

#### Scenario: Deploy with signed closure
- **WHEN** `just deploy velomo-alpha` runs from framework-13
- **THEN** the copy succeeds and the switch completes

#### Scenario: Unsigned path from nh
- **WHEN** nh on a server runs `nix copy` of an unsigned path into the server store, or passes `--option` settings that only trusted users may set
- **THEN** the Nix daemon rejects it

### Requirement: Tailnet traffic reaches only declared ports
On servers, the firewall SHALL NOT trust `tailscale0` as a whole. Ports reachable over the tailnet SHALL be listed explicitly.

#### Scenario: Undeclared port over tailnet
- **WHEN** a tailnet peer connects to a server port that is not in that host's tailnet allow-list
- **THEN** the firewall drops the connection

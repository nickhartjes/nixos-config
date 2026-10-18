## Purpose

Defines what grants root or unlocks a session on framework-13. Root needs knowledge of a secret (the password or the security key's PIN), and code running as nh cannot raise its own privileges or capture input.

## ADDED Requirements

### Requirement: Security key is two-factor and centrally enrolled
`pam_u2f` SHALL read key mappings from a root-owned file managed by the NixOS config. A security key SHALL authenticate only together with its PIN.

#### Scenario: Self-enrolled key
- **WHEN** nh writes a new mapping to `~/.config/Yubico/u2f_keys`
- **THEN** that key doesn't authenticate for sudo, login or the lock screen

#### Scenario: Enrolled key
- **WHEN** the enrolled YubiKey is touched and its PIN entered at a sudo prompt
- **THEN** sudo succeeds

#### Scenario: Key without PIN
- **WHEN** the enrolled key is touched but the PIN is not entered or is wrong
- **THEN** u2f fails and PAM falls through to the password

### Requirement: Fingerprint never grants root
Fingerprint authentication SHALL be disabled for sudo, polkit, su and run0. It MAY stay enabled for session unlock and login.

#### Scenario: sudo with fingerprint only
- **WHEN** nh runs `sudo true` and offers only a fingerprint
- **THEN** sudo doesn't succeed until the password or key plus PIN is given

### Requirement: Unprivileged user has no root-equivalent groups
On framework-13, nh SHALL NOT be a member of `docker` or `input`. Docker SHALL run rootless for nh. `libvirtd` membership stays as a documented accepted risk.

#### Scenario: Docker usage
- **WHEN** nh runs `docker run --rm hello-world`
- **THEN** it succeeds against the rootless daemon (`DOCKER_HOST` points at `$XDG_RUNTIME_DIR/docker.sock`), and `id nh` lists neither `docker` nor `input`

#### Scenario: Host root via container
- **WHEN** nh runs `docker run -v /:/h alpine touch /h/root/x`
- **THEN** it fails, because the container's root maps to nh's subuid range

### Requirement: Session always locks on idle and suspend
When the shell's lock IPC fails, the idle and before-sleep lock in niri and mango SHALL fall back to a standalone locker.

#### Scenario: Shell not running
- **WHEN** Noctalia (niri) or DMS (mango) has crashed and the idle timeout or suspend fires
- **THEN** swaylock locks the session

### Requirement: Auto-upgrade applies only the protected branch
framework-13's auto-upgrade SHALL build only from the `stable` branch of `github:nickhartjes/nixos-config`. That branch SHALL have protection that prevents force pushes and deletion.

#### Scenario: Commit pushed to main
- **WHEN** a commit is pushed to `main` but not to `stable`
- **THEN** the next auto-upgrade doesn't apply it

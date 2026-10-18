## Purpose

Defines which terminal user interfaces for git and container management are installed for the nh user, and on which hosts.

## ADDED Requirements

### Requirement: lazygit available wherever git is configured
nh SHALL have `lazygit` on PATH on every host where nh's git component is enabled.

#### Scenario: Workstation with git
- **WHEN** nh opens a terminal on framework-13
- **THEN** `lazygit --version` succeeds

### Requirement: lazydocker only on Docker hosts
nh SHALL have `lazydocker` on PATH exactly on hosts where a Docker daemon is enabled, either system-wide or rootless (per-user), and SHALL NOT have it on hosts without Docker.

#### Scenario: Host with Docker
- **WHEN** nh opens a terminal on framework-13 (Docker enabled)
- **THEN** `lazydocker --version` succeeds

#### Scenario: Host without Docker
- **WHEN** nh's profile is evaluated for vm-desktop (Podman, no Docker)
- **THEN** lazydocker is not installed

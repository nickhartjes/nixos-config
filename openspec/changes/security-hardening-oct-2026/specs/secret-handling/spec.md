## Purpose

Defines how agenix secrets are permissioned on hosts, edited by the operator, and delivered to the processes that use them, so that decrypted values reach only their consumers.

## ADDED Requirements

### Requirement: Decrypted secrets are not world-readable
No decrypted agenix secret on any host SHALL have the other-read bit set. A secret shared by several consumers SHALL be readable only through a dedicated group.

#### Scenario: Unprivileged read on velomo-alpha
- **WHEN** a user outside the secret's owner and group (for example `nobody`) runs `cat /run/agenix/velomo-alpha/scraper-app.env`
- **THEN** it fails with permission denied

#### Scenario: Intended consumers still read
- **WHEN** doco-cd deploys a stack and the GitHub runners start
- **THEN** they read their secrets and run successfully

### Requirement: Only live secrets are decrypted
A host SHALL decrypt only secrets that one of its services uses. Secrets for retired services SHALL be removed from both the host config and `secrets/secrets.nix`.

#### Scenario: Authelia retired
- **WHEN** velomo-alpha activates
- **THEN** no `authelia-*` file exists under `/run/agenix`

### Requirement: Secret editing leaves no plaintext copies
The repo's secret-editing recipes SHALL use the pinned `agenix` from the flake. They SHALL use an editor that keeps no history or backup of the temporary plaintext file.

#### Scenario: Edit a secret
- **WHEN** the operator runs `just edit <secret>` in `secrets/`
- **THEN** no `nix run github:` fetch happens, and after saving, no copy of the plaintext exists outside agenix's temp dir, which agenix removes

### Requirement: Repo tooling runs pinned code
justfile recipes SHALL NOT run unpinned remote flakes (`nix run github:…` without a locked input), especially under sudo or with access to decryption keys.

#### Scenario: Format and lint
- **WHEN** the operator runs the format, lint or install recipes
- **THEN** the tools come from `flake.lock`-pinned inputs or nixpkgs

### Requirement: API tokens are scoped to their consumer
Tokens for MCP integrations (Grafana service account, Hevy) SHALL NOT be exported into the general shell environment. Only the process that needs a token SHALL receive it.

#### Scenario: New shell
- **WHEN** the operator opens a new zsh session
- **THEN** `env` shows neither `GRAFANA_SA_TOKEN` nor `HEVY_API_KEY`

#### Scenario: MCP start
- **WHEN** the Grafana or Hevy MCP server starts
- **THEN** it receives its token and authenticates

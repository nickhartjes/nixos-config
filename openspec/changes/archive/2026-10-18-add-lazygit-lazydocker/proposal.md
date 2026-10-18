## Why

Omarchy ships lazygit and lazydocker as its default git and container TUIs; nh has neither, so git staging/rebasing and container inspection happen through raw CLI commands.

## What Changes

- Install lazygit for nh on every host where the git component is enabled.
- Install lazydocker for nh only on hosts that run Docker (framework-13; servers do not use nh's Home Manager profile).
- Docker's port-binding behaviour is **not** part of this change; it is covered by `security-hardening-oct-2026` (requirement "Docker publishes to loopback by default").

## Capabilities

### New Capabilities
- `developer-tui-tools`: Which terminal UIs for git and containers are available to nh, and on which hosts.

### Modified Capabilities

## Impact

- `components/home-manager/development/git.nix`, new `components/home-manager/development/infrastructure/lazydocker.nix`, `users/nh/development.nix`.
- No new flake inputs; packages come from nixpkgs via Home Manager's `programs.lazygit` / `programs.lazydocker`.

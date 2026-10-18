## 1. lazygit

- [x] 1.1 Add `programs.lazygit.enable = true` inside the enabled block of `components/home-manager/development/git.nix`; verify `nix eval .#nixosConfigurations.framework-13.config.home-manager.users.nh.programs.lazygit.enable` → `true`

## 2. lazydocker

- [x] 2.1 Create `components/home-manager/development/infrastructure/lazydocker.nix` with option `components.development.infrastructure.lazydocker.enable` (same shape as `k9s.nix`) setting `programs.lazydocker.enable = true`, and import it from `infrastructure/default.nix`; verify the option evaluates
- [x] 2.2 In `users/nh/development.nix`, set `lazydocker.enable = osConfig.virtualisation.docker.enable || osConfig.virtualisation.docker.rootless.enable` (rootless counts: the security-hardening change moves framework-13 to rootless Docker) (take `osConfig` as a module argument, as `users/nh/desktop.nix` does); verify `programs.lazydocker.enable` is `true` for framework-13 and `false` for vm-desktop

## 3. Verification

- [x] 3.1 All five nixosConfigurations evaluate and `nix build` of framework-13's toplevel succeeds
- [x] 3.2 After the user rebuilds: `lazygit --version` and `lazydocker --version` succeed on framework-13

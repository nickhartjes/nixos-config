
# List available commands
default:
    @just --list

# Deploy system configuration
deploy SYSTEM:
    nixos-rebuild switch --flake .#{{SYSTEM}} --target-host {{SYSTEM}} --use-remote-sudo

# Update flake
update:
    nix flake update

# Check flake
check:
    nix flake check

# Show flake info
show:
    nix flake show

# Build system configuration
build SYSTEM:
    nixos-rebuild build --flake .#{{SYSTEM}}

# Enter a development shell
dev-shell:
    nix develop


deadcode:
    nix run github:astro/deadnix

formatter:
    nix run github:kamadorueda/alejandra 
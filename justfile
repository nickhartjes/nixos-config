
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


install-flake:
    export NIX_CONFIG="experimental-features = nix-command flakes"
    nix-shell -p git --run "git clone https://github.com/nickhartjes/nixos-config.git"


# Build the custom NixOS ISO for installation
build-iso:
    nix build ./installation/iso#nixosConfigurations.installationIso.config.system.build.isoImage --out-link installation/iso-result


clean-install HOSTNAME:
    export NIX_CONFIG="experimental-features = nix-command flakes"
    nix-shell -p git --run "git clone https://github.com/nickhartjes/nixos-config.git ~/nixos-config"
    sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ~/nixos-config/hosts/{{HOSTNAME}}/disko-config.nix
    cd ~/nixos-config && sudo nixos-install --flake .#{{HOSTNAME}}
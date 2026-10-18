
# List available commands
default:
    @just --list

# Deploy system configuration. Remote sudo authenticates via the forwarded SSH
# agent (security.pam.sshAgentAuth), so no password prompt.
deploy SYSTEM:
    NIX_SSHOPTS="-o ForwardAgent=yes" nixos-rebuild switch --flake .#{{SYSTEM}} --target-host {{SYSTEM}} --elevate=sudo

# Deploy with a sudo password prompt, for hosts without sshAgentAuth yet
deploy-password SYSTEM:
    NIX_SSHOPTS="-o ForwardAgent=yes" nixos-rebuild switch --flake .#{{SYSTEM}} --target-host {{SYSTEM}} --elevate=sudo --ask-sudo-password

# Deploy velomo-alpha (production host: doco-cd, zot registry, beszel, scraper-app stack)
deploy-velomo:
    just deploy velomo-alpha

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


# Tools come from the pinned nixpkgs (nix.registry follows flake.lock) or
# from this flake's own inputs, never from a remote HEAD.
deadcode:
    nix run nixpkgs#deadnix

formatter:
    nix run nixpkgs#alejandra -- .


install-flake:
    export NIX_CONFIG="experimental-features = nix-command flakes"
    nix-shell -p git --run "git clone https://github.com/nickhartjes/nixos-config.git"


# Build the custom NixOS ISO for installation
build-iso:
    nix build ./installation/iso#nixosConfigurations.installationIso.config.system.build.isoImage --out-link installation/iso-result


clean-install HOSTNAME:
    export NIX_CONFIG="experimental-features = nix-command flakes"
    nix-shell -p git --run "git clone https://github.com/nickhartjes/nixos-config.git ~/nixos-config"
    sudo nix --experimental-features "nix-command flakes" run --inputs-from ~/nixos-config disko -- --mode destroy,format,mount ~/nixos-config/hosts/{{HOSTNAME}}/disko-config.nix
    cd ~/nixos-config && sudo nixos-install --flake .#{{HOSTNAME}}


# Install a host remotely with nixos-anywhere. EXTRA is a directory mirroring
# the target's filesystem root; seeding /etc/ssh/ssh_host_ed25519_key there lets
# agenix decrypt on the very first boot, avoiding an install-then-rekey pass.
# Usage: just install-nanoclaw 10.0.60.51
install-nanoclaw IP EXTRA="/home/nh/.local/state/n100-nanoclaw-extra":
    nix run nixpkgs#nixos-anywhere -- \
        --extra-files {{EXTRA}} \
        --flake .#n100-nanoclaw \
        root@{{IP}}

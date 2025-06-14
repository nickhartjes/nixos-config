# NixOs configuration  [<img src="https://nixos.org/logo/nixos-logo-only-hires.png" width="200" align="right" alt="NixOS">](https://nixos.org)

> This repopository contains my NixOS configuration files. It is a work in progress and may not be suitable for production use.

## What is Nix and NixOS? 

[Nix](https://github.com/nixos/nix) is a powerful package manager for Linux and other Unix systems that makes package management reliable and reproducible.

[NixOS](https://nixos.org/) is a Linux distribution powered by the [Nix](https://github.com/nixos/nix) package manager, built for reproducibility, reliability, and declarative system management. NixOS allows users to define their entire system configuration in code, typically using a structured, modular setup composed of multiple configuration files. This includes system packages, services, kernel options, user environments, and more.

Through its atomic upgrades and rollbacks, pure functional approach, and immutable infrastructure capabilities, NixOS is ideal for those seeking to maintain consistent environments across machines or deployments — from local development to cloud infrastructure.

## What tools are used in this configuration?

### Home Manager
[Home-manager](https://nix-community.github.io/home-manager/) is a tool built on top of the Nix ecosystem that allows you to manage user-specific configuration in a declarative way — just like you manage system-level settings in NixOS. Instead of manually tweaking `~/.bashrc`, `~/.zshrc`, `~/.config`, or installing user-level packages one-by-one, Home Manager lets you define all of that in Nix code. You write a configuration file (or set of files) describing your dotfiles, packages, and shell settings, and Home Manager takes care of installing and wiring them up correctly.

### Disko
[Disko](https://github.com/nix-community/disko) is a declarative disk partitioning and formatting tool for NixOS installations, developed by the Nix community. It allows you to define your entire disk layout in Nix, just like you define system and user configurations.

With disko, you write a Nix expression describing your storage setup — including partitions, filesystems, encryption, RAID, LVM, and mount points — and disko will create and format the disks accordingly.

### Agenix
agenix is a declarative secret management tool for NixOS and other systems using the Nix package manager. It lets you store encrypted secrets (like API keys, SSH keys, or config files) in your Git repository — encrypted to specific machines or users — and then decrypt and deploy them safely at runtime.

It’s built on top of age, a simple, modern encryption tool by Filippo Valsorda, designed to replace GPG with a more minimal and secure design.

## Getting Started


## Resources and Information

### Helpful Links
- [NixOS](https://nixos.org/) - The NixOS website.
- [Awesome Nix](https://nix-community.github.io/awesome-nix/) - The `awesome-nix` website.
- [Nix.dev](https://nix.dev/) - The official documentation for the Nix ecosystem.

### Inspiring Configurations
- https://github.com/Misterio77/nix-starter-configs
- https://github.com/Misterio77/nix-config
- https://code.m3ta.dev/m3tam3re/nixcfg
- https://github.com/khaneliman/khanelinix

### Youtube
#### Nix / NixOs related channels
- [Sascha Koenig](https://www.youtube.com/@m3tam3re)
- [Vimjoyer](https://www.youtube.com/@vimjoyer)

#### Nix / NixOs related videos
- [Fireship - Nix in 100 Seconds](https://www.youtube.com/watch?v=FJVFXsNzYZQ)
- [Dreams of Autonomy - Nix is my favorite package manager to use on MacOs](https://www.youtube.com/watch?v=Z8BL8mdzWHI&t)
- [Ampersand - Full NixOS Guide: Everything You Need to Know in One Place!](https://www.youtube.com/watch?v=nLwbNhSxLd4)

```shell
nix flake init --template github:edolstra/nix-flake-template 
```

```shell
nix run github:nix-community/nixos-anywhere -- --flake  .#blackhawk-vm --vm-test
```
```shell
nix run github:nix-community/nixos-anywhere -- --flake  .#blackhawk-vm --target-host nh@192.168.122.110
```

```shell
nix-shell -p curl just --run "curl -s https://raw.githubusercontent.com/nickhartjes/nixos-config/refs/heads/main/justfile | just -f - install-flake"
```

```shell
sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake github.com/nickhartjes/nixos-config#blackhawk-vm --disk main /dev/vda
```


```shell
sudo nix run 'github:nix-community/disko/latest#disko-install' -- --flake .#blackhawk-vm --disk nixos /dev/vda
```

```shell
nix-shell -p just curl --run 'just --justfile <(curl -s https://raw.githubusercontent.com/nickhartjes/nixos-config/refs/heads/main/justfile) clean-install vm-blackhawk'
```

```shell
sudo nix run nixpkgs#nixos-facter -- -o facter.json
```
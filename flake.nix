#  __   __   __    __
# |  \ |  | |  |  |  |
# |   \|  | |  |__|  |  Nick Hartjes
# |    `  | |   __   |  https://nickhartjes.nl
# |  |\   | |  |  |  |  https://github.com/nickhartjes/
# |__| \__| |__|  |__|
#
{
  description = "NH System Flake Configuration";

  inputs = {
    # Home Manager for managing user-specific configurations
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Main Nixpkgs (unstable channel)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable Nixpkgs (specific version, e.g., for certain packages or modules)
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # Agenix for managing secrets
    agenix.url = "github:ryantm/agenix";

    # NixOS profiles to optimize settings for different hardware.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Disko for declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Example of a non-flake input (e.g., for dotfiles)
    dotfiles = {
      url = "git+https://github.com/nickhartjes/dotfiles-flake-demo.git";
      flake = false; # Indicates this is not a flake
    };

    # Nix-darwin for managing macOS configurations (not used in this flake)
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Microcode updates for Intel and AMD CPUs
    ucodenix.url = "github:e-tho/ucodenix";
  };

  # --- Outputs ---
  # Defines what this flake provides (packages, NixOS configurations, etc.)
  outputs = {
    auto-cpufreq, # Auto CPU frequency scaling
    self, # A reference to this flake's own outputs
    agenix, # Agenix input
    home-manager, # Home Manager input
    nix-darwin, # Nix-darwin input (though not used in the current systems list)
    nixpkgs, # Nixpkgs input
    nixpkgs-stable, # Nixpkgs stable input
    nixos-hardware,
    lanzaboote,
    ucodenix,
    ... # Catches any other inputs
  } @ inputs: let
    # `@ inputs` makes all inputs available under the `inputs` attribute set
    # Inherit `outputs` from `self` to allow recursive references if needed
    inherit (self) outputs;

    # Define the list of systems this flake supports
    systems = [
      "x86_64-linux" # Common 64-bit Linux
      # "aarch64-linux"  # ARM 64-bit Linux
      # "i686-linux"     # 32-bit Linux
      # "aarch64-darwin" # ARM 64-bit macOS
      # "x86_64-darwin"  # Intel 64-bit macOS
    ];

    # Helper function to generate an attribute set for each system
    # This is useful for defining packages or other outputs per system
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Packages provided by this flake
    # It iterates over `forAllSystems` and imports packages for each system
    packages =
      forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # Overlays are modifications or additions to Nixpkgs
    overlays = import ./overlays {inherit inputs;}; # Passes inputs to the overlays

    # Home Manager modules provided by this flake
    # These can be imported by Home Manager configurations
    # homeManagerModules = import ./modules/home-manager;

    # NixOS configurations provided by this flake
    # Each attribute in this set is a complete NixOS system configuration
    nixosConfigurations = {
      # Example structure for a NixOS configuration
      # <hostname> = nixpkgs.lib.nixosSystem {
      #   specialArgs = {inherit inputs outputs;};
      #   modules = [
      #     ./hosts/<hostname>
      #     inputs.disko.nixosModules.disko
      #     agenix.nixosModules.default
      #   ];
      # };

      # NixOS configuration for 'vm-blackhawk'
      vm-blackhawk = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Specify the system architecture
        specialArgs = {inherit inputs outputs;}; # Pass inputs and flake outputs to the modules
        modules = [
          ./hosts/vm-blackhawk # Host-specific configuration
          inputs.disko.nixosModules.disko # Disko module
          agenix.nixosModules.default # Agenix module
        ];
      };

      vm-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Specify the system architecture
        specialArgs = {inherit inputs outputs;}; # Pass inputs and flake outputs to the modules
        modules = [
          ./hosts/vm-desktop # Host-specific configuration
          inputs.disko.nixosModules.disko # Disko module
          agenix.nixosModules.default # Agenix module
        ];
      };

      framework-13 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Specify the system architecture
        specialArgs = {inherit inputs outputs;}; # Pass inputs and flake outputs to the modules
        modules = [
          ./hosts/framework-13 # Host-specific configuration
          inputs.disko.nixosModules.disko # Disko module
          agenix.nixosModules.default # Agenix module
          nixos-hardware.nixosModules.framework-amd-ai-300-series # NixOS hardware module for framework-13
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.ucodenix.nixosModules.default
          auto-cpufreq.nixosModules.default
        ];
      };

      # NixOS configuration for 'm3-hermes-hetzner'
      m3-hermes-hetzner = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Specify the system architecture
        specialArgs = {inherit inputs outputs;}; # Pass inputs and flake outputs to the modules
        modules = [
          ./hosts/m3-kratos # Host-specific configuration
          inputs.disko.nixosModules.disko # Disko module
          agenix.nixosModules.default # Agenix module
        ];
      };
    };
  };
}

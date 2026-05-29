{
  pkgs,
  lib,
  inputs,
  outputs,
  config,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./configuration.nix
    ../../components/nixos
    inputs.home-manager.nixosModules.home-manager

    # Imported in Phase 2 once agenix secrets exist:
    # ./secrets.nix

    # Imported in Phase 3 once docker + secrets are ready:
    # ./services
  ];

  # home-manager wiring kept available even though no user-level HM modules are loaded.
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs outputs;};
  };

  # Phase 3 enables this:
  # components.virtualization.docker.enable = true;
}

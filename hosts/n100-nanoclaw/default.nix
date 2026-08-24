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
    # Server-relevant components only. desktop-manager is skipped: it needs
    # the mango/niri nixos modules, which a headless host does not load.
    ../../components/nixos/system
    ../../components/nixos/hardware
    ../../components/nixos/virtualization
    inputs.home-manager.nixosModules.home-manager
    ./secrets.nix
  ];

  # home-manager wiring kept available even though no HM user modules load.
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs outputs;};
  };

  components.virtualization.docker.enable = true;
}

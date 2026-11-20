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
    # Import server-relevant nixos components (skip desktop-manager which requires
    # inputs.mango and inputs.niri nixos modules not included for a headless host).
    ../../components/nixos/system
    ../../components/nixos/hardware
    ../../components/nixos/virtualization
    inputs.home-manager.nixosModules.home-manager
    ./secrets.nix
    ./services
  ];

  # T3 desktop SSH bootstrap downloads a generic Linux executable.
  programs.nix-ld.enable = true;

  users.users.nh.linger = true;

  # T3 runs as nh; provider credentials and project data stay in its home.
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = {inherit inputs outputs;};
    useGlobalPkgs = true;
    users.nh = {
      imports = [../../components/home-manager/application/ai/t3code.nix];
      home.stateVersion = "26.05";
      home.packages = with pkgs; [codex claude-code gh ripgrep];
      components.application.ai.t3code = {
        enable = true;
        server.enable = true;
      };
    };
  };

  components.virtualization.docker.enable = true;
}

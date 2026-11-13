{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ./configuration.nix
    ./secrets.nix
    ./specdeck.nix
    ./ja-instituut.nix
  ];
}

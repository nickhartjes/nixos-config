{pkgs, ...}: {
  imports = [
    ./editor
    ./infrastructure
    ./git.nix
  ];
}

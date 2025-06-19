{pkgs, ...}: {
  imports = [
    ./editor
    ./infrastructure
    ./languages
    ./git.nix
  ];
}

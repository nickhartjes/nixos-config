{pkgs, ...}: {
  imports = [
    ./editor
    ./infrastructure
    ./languages
    ./git.nix
    ./mise.nix
  ];
}

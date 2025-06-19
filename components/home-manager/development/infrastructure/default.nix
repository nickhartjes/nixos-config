{pkgs, ...}: {
  imports = [
    ./opentofu.nix
    ./terraform.nix
    ./kubernetes.nix
    ./aws.nix
  ];
}

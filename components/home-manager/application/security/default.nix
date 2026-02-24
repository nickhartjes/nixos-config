{pkgs, ...}: {
  imports = [
    ./bitwarden.nix
    ./lynis.nix
    ./openssl.nix
    ./protonvpn.nix
  ];
}

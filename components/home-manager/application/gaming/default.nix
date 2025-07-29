{pkgs, ...}: {
  imports = [
    ./steam.nix
    ./lutris.nix
    ./ryujinx.nix
  ];
}

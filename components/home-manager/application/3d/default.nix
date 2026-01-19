{pkgs, ...}: {
  imports = [
    ./bambu-studio.nix
    ./freecad.nix
    ./openscad.nix
  ];
}

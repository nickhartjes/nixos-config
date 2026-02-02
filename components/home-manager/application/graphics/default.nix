{pkgs, ...}: {
  imports = [
    ./gimp.nix
    ./inkscape.nix
    ./flameshot.nix
  ];
}

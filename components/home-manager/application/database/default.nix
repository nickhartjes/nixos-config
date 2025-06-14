{pkgs, ...}: {
  imports = [
    ./dbeaver.nix
    ./pgadmin.nix
  ];
}

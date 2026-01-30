{pkgs, ...}: {
  imports = [
    ./dbeaver.nix
    ./pgadmin.nix
    ./pgmodeler.nix
    ./supabase.nix
  ];
}

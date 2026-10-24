{pkgs, ...}: {
  # Define your custom packages here
  fonts-custom = pkgs.callPackage ./fonts-custom {};
  orca-ide = pkgs.callPackage ./orca-ide {};
  solidcraft = pkgs.callPackage ./solidcraft {};
}

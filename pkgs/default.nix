{pkgs, ...}: {
  # Define your custom packages here
  fonts-custom = pkgs.callPackage ./fonts-custom {};
  k10s = pkgs.callPackage ./k10s {};
  orca-ide = pkgs.callPackage ./orca-ide {};
  solidcraft = pkgs.callPackage ./solidcraft {};
  thinkrail = pkgs.callPackage ./thinkrail {};
}

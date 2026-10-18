{pkgs, ...}: {
  # Define your custom packages here
  fonts-custom = pkgs.callPackage ./fonts-custom {};
}

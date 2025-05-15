{pkgs, ...}: {
  # Define your custom packages here
  zellij-ps = pkgs.callPackage ./zellij-ps {};
  # n8n-custom = pkgs.callPackage ./n8n-custom {};
}

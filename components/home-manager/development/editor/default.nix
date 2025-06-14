{pkgs, ...}: {
  imports = [
    ./intellij.nix
    ./vscode.nix
    ./zed.nix
  ];
}

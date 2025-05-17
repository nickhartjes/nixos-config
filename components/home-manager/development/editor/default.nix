{pkgs, ...}: {
  imports = [
    ./vscode.nix
    ./zed-editor.nix
  ];
}

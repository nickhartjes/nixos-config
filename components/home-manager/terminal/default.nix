{pkgs, ...}: {
  imports = [
    ./alacritty.nix
    ./foot.nix
    ./ghostty.nix
    ./kitty.nix
    ./wezterm.nix
  ];
}

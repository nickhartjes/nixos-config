{pkgs, ...}: {
  imports = [
    ./fonts.nix
    ./hyprland.nix
    ./wayland.nix
    # ./plasma.nix
  ];

  home.packages = with pkgs; [
  ];
}

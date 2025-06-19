{pkgs, ...}: {
  imports = [
    ./slack.nix
    ./discord.nix
    ./signal.nix
    ./telegram.nix
  ];
}

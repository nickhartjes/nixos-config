{pkgs, ...}: {
  imports = [
    ./slack.nix
    ./discord.nix
  ];
}

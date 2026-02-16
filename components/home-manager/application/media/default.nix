{pkgs, ...}: {
  imports = [
    ./kdenlive.nix
    ./mpv.nix
    ./obs.nix
    ./vlc.nix
  ];
}

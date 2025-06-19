{pkgs, ...}: {
  imports = [
    ./browser
    ./music
    ./ai
    ./communication
    ./graphics
    ./database
    ./office
    ./security
    ./gaming
    ./system
  ];
}

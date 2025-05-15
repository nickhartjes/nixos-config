{
  imports = [
    ../common
    ../features/cli
    ./home-server.nix
  ];

  features = {
    cli = {
      fish.enable = true;
      fzf.enable = true;
      neofetch.enable = true;
    };
  };
}

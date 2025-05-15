{
  imports = [
    ../../common
    ../../features/cli
  ];

  features = {
    cli = {
      fish.enable = true;
      fzf.enable = true;
      neofetch.enable = true;
    };
    desktop = {
      plasma.enable = true;
      hyprland.enable = false;
    };
  };
}

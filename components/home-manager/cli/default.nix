{pkgs, ...}: {
  imports = [
    ./bat.nix
    ./fastfetch.nix
    ./fish.nix
    ./fzf.nix
    ./neofetch.nix
    ./neovim.nix
    ./nh.nix
    ./zsh.nix
  ];

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  # programs.eza = {
  #   enable = true;
  #   enableFishIntegration = true;
  #   enableBashIntegration = true;
  #   extraOptions = ["-l" "--icons" "--git" "-a"];
  # };

  home.packages = with pkgs; [
    coreutils
    fd
    gcc
    htop
    httpie
    jq
    procs
    ripgrep
    tldr
    zip
  ];
}

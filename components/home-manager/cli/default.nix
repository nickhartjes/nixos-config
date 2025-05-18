{pkgs, ...}: {
  imports = [
    ./fish.nix
    ./fzf.nix
    ./neofetch.nix
    ./nh.nix
  ];

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    extraOptions = ["-l" "--icons" "--git" "-a"];
  };

  programs.bat = {enable = true;};

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

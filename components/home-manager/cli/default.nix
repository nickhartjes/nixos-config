{pkgs, ...}: {
  imports = [
    ./bat.nix
    ./fastfetch.nix
    ./fish.nix
    ./fzf.nix
    ./neofetch.nix
    ./neovim.nix
    ./nvtop.nix
    ./nh.nix
    ./zsh.nix
    ./ssh.nix
  ];

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    # Zsh init is placed at the end of .zshrc manually in zsh.nix
    # (so zoxide's chpwd/precmd hooks aren't shadowed by mise et al).
    enableZshIntegration = false;
    options = ["--cmd cd"];
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

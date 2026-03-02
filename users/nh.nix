{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./nh/secrets.nix
  ];

  users.users.nh = {
    # $ nix-shell -p mkpasswd --run 'mkpasswd <password>'
    initialHashedPassword = "$y$j9T$SWeufZ9NrHX0.d.w72nc20$1zKkVcJHZfIvS5VMqhdP5RwQ7wQHzbsIi.ArDYRXDK7";
    isNormalUser = true;

    ignoreShellProgramCheck = true;
    shell = pkgs.zsh;

    home = "/home/nh";

    description = "nh";
    extraGroups = [
      "wheel"
      "networkmanager"
      "libvirtd"
      "flatpak"
      "audio"
      "video"
      "plugdev"
      "input"
      "kvm"
      "qemu-libvirtd"
      "docker"
      "podman"
    ];
    openssh.authorizedKeys.keys = [
      "sh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8Fzq/ktI9g9FYsADc8NkaYDhHuXIPPPxwRjXT7Gcwk info@nickhartjes.nl"
    ];
    packages = [
      inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  environment = {
    variables = {
      TERMINAL = "ghostty";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  home-manager.users.nh = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      ../components/home-manager
      inputs.plasma-manager.homeModules.plasma-manager
      ./nh/applications.nix
      ./nh/development.nix
      ./nh/desktop.nix
      ./nh/repositories.nix
    ];
    home.stateVersion = "24.11";

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "anytype"
        "anytype-heart"
        "bambu-studio"
        "claude-code"
        "corefonts"
        "vscode-extension-anthropic-claude-code"
        "dbeaver-bin"
        "discord"
        "jetbrains-toolbox"
        "lmstudio"
        "lutris"
        "obsidian"
        "protonvpn-cli"
        "protonvpn-gui"
        "signal-desktop"
        "slack"
        "spotify"
        "steam-original"
        "steam-unwrapped"
        "steam"
        "telegram-desktop"
        "terraform"
        "vscode"
      ];

    home.packages = with pkgs; [
      fd
      obsidian
      alejandra
      wl-clipboard
      catppuccin-kde
      just
    ];

    home.shellAliases = {
      repo-sync = "~/.local/bin/repo-manager";
      repo-log = "tail -f ~/.local/state/repo-manager.log";
    };
  };
}

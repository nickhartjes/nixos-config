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
    home.stateVersion = "26.05";

    # bitwarden-desktop pins electron_39, which nixpkgs (both nixos-unstable
    # and master, checked 2026-06-03) marks as EOL. Lives here, not at the
    # host level, because home-manager.useGlobalPkgs is off — HM has its own
    # nixpkgs.config. Drop once bitwarden-desktop moves to electron_40+.
    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];

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
        "idea"
        "jetbrains-toolbox"
        "lmstudio"
        "lutris"
        "obsidian"
        "protonvpn-cli"
        "proton-vpn"
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

    home.packages = (with pkgs; [
      fd
      obsidian
      alejandra
      wl-clipboard
      catppuccin-kde
      just
    ]) ++ [
      inputs.lazyjust.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    home.shellAliases = {
      repo-sync = "~/.local/bin/repo-manager";
      repo-log = "tail -f ~/.local/state/repo-manager.log";
    };

    # Load the Grafana MCP service-account token (GRAFANA_SA_TOKEN) for the
    # Velomo prod observability stack. agenix decrypts the token to
    # ~/.config/velomo-grafana-sa.env on framework-13 (owner nh; see
    # hosts/framework-13/secrets.nix); this sources it so the grafana MCP in
    # scraper's .mcp.json gets ${GRAFANA_SA_TOKEN}. Guarded so it's a no-op on
    # machines/hosts where the secret isn't provisioned.
    programs.zsh.initContent = lib.mkOrder 1500 ''
      [[ -f ~/.config/velomo-grafana-sa.env ]] && source ~/.config/velomo-grafana-sa.env
    '';
  };
}

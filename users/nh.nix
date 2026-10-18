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
    # No password in the repo: it is public. On a fresh install set one with
    # `nixos-enter --root /mnt -c 'passwd nh'` before rebooting.
    isNormalUser = true;

    ignoreShellProgramCheck = true;
    shell = pkgs.zsh;

    home = "/home/nh";

    description = "nh";
    # docker, podman and libvirtd are root-equivalent, so only join them on
    # hosts that actually run the service.
    extraGroups =
      [
        "wheel"
        "networkmanager"
        "audio"
        "video"
        "plugdev"
        "input"
      ]
      ++ lib.optionals config.virtualisation.libvirtd.enable ["libvirtd" "kvm"]
      ++ lib.optional config.virtualisation.docker.enable "docker"
      ++ lib.optional config.virtualisation.podman.enable "podman";
    openssh.authorizedKeys.keys = [
      # framework-13 user keys, kept in sync with secrets/secrets.nix
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
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
    lib,
    ...
  }: {
    imports = [
      ../components/home-manager
      inputs.plasma-manager.homeModules.plasma-manager
      inputs.artcraft.homeManagerModules.default
      inputs.oh-my-pi.homeManagerModules.default
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
    #
    # cypress 15.19.0 bundles electron 37.6.0, EOL since 2025-10-04 (checked
    # 2026-09-07). Installed by components/home-manager/development/languages/
    # nodejs.nix. Drop once cypress in nixpkgs bumps past electron 37.
    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
      "cypress-15.19.0"
    ];

    # TEMP (2026-07-26): pandas-stubs test collection breaks under pytest 9,
    # failing markitdown -> alpaca. Same fix as overlays/default.nix
    # modifications, but HM needs it separately: useGlobalPkgs is off and
    # nothing imports components/home-manager/common (where the shared overlay
    # list lives — dead code), so HM's nixpkgs has NO overlays. Drop after a
    # flake update builds without it.
    nixpkgs.overlays = [
      # TEMP (2026-08-07): hyprland 0.56.1 cannot configure against glaze 8,
      # which is what the nixpkgs rev we pin ships (NixOS/nixpkgs#549246).
      # Same fix as overlays/default.nix modifications — duplicated here for
      # the reason spelled out above (HM's nixpkgs gets no overlays). Drop
      # both together once the main nixpkgs pin can move past e0832b87.
      (_final: prev: let
        unstable = import inputs.nixpkgs-unstable {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      in {
        inherit (unstable) hyprland xdg-desktop-portal-hyprland;
      })

      (_final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions
          ++ [
            (_pyfinal: pyprev: {
              # pythonImportsCheck imports pandas, which only comes in via the
              # (now skipped) test deps — disable it along with the tests.
              pandas-stubs = pyprev.pandas-stubs.overridePythonAttrs (_: {
                doCheck = false;
                pythonImportsCheck = [];
              });
            })
          ];
      })
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
        # nixpkgs split discord into a wrapper + unwrapped derivation; the
        # predicate sees the inner name, so both have to be listed.
        "discord-unwrapped"
        # nixpkgs renamed jetbrains.idea -> intellij-idea (alias added
        # 2026-08-15); the predicate sees the new pname.
        "intellij-idea"
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

    home.packages =
      (with pkgs; [
        fd
        obsidian
        alejandra
        wl-clipboard
        catppuccin-kde
        just
        uv # Python tool/proj manager
      ])
      ++ [
        inputs.lazyjust.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

    home.shellAliases = {
      repo-sync = "~/.local/bin/repo-manager";
      repo-log = "tail -f ~/.local/state/repo-manager.log";
    };

    home.sessionPath = [
      # uv installs tool executables here.
      "$HOME/.local/bin"
      # CLI shims from self-updating apps (LM Studio's `lms`, JetBrains Toolbox
      # launchers). Their installers append these to ~/.bashrc/.profile, which
      # zsh never reads.
      "$HOME/.lmstudio/bin"
      "$HOME/.local/share/JetBrains/Toolbox/scripts"
    ];

    # Loads the Grafana MCP service-account token (GRAFANA_SA_TOKEN) for the
    # Velomo prod observability stack. agenix decrypts the token to
    # ~/.config/velomo-grafana-sa.env on framework-13 (owner nh; see
    # hosts/framework-13/secrets.nix); this sources it so the grafana MCP in
    # scraper's .mcp.json gets ${GRAFANA_SA_TOKEN}. Guarded so it's a no-op on
    # machines/hosts where the secret isn't provisioned.
    #
    # hevy-mcp.env carries HEVY_API_KEY for the hevy MCP in the NH Obsidian
    # vault's .mcp.json (same agenix flow as the grafana token).
    programs.zsh.initContent = lib.mkOrder 1500 ''
      [[ -f ~/.config/velomo-grafana-sa.env ]] && source ~/.config/velomo-grafana-sa.env
      [[ -f ~/.config/hevy-mcp.env ]] && source ~/.config/hevy-mcp.env
    '';
  };
}

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
    lib,
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

    home.packages =
      (with pkgs; [
        fd
        obsidian
        alejandra
        wl-clipboard
        catppuccin-kde
        just
        uv # Python tool/proj manager; also backs the headroom install below
      ])
      ++ [
        inputs.lazyjust.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

    home.shellAliases = {
      repo-sync = "~/.local/bin/repo-manager";
      repo-log = "tail -f ~/.local/state/repo-manager.log";
    };

    # uv installs tool executables (e.g. headroom) here.
    home.sessionPath = ["$HOME/.local/bin"];

    # Headroom context-compression CLI. Installed via `uv tool` rather than
    # mise's pipx backend, which silently drops the [all] extras (mcp/proxy/
    # ml/...) when it pins the version. nix-ld (hosts/common) lets headroom's
    # prebuilt Rust-extension wheels load. Idempotent: only installs when the
    # binary is missing, so normal switches are a fast no-op and need no
    # network. To upgrade: `uv tool upgrade headroom-ai`.
    home.activation.installHeadroom = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ ! -x "$HOME/.local/bin/headroom" ]]; then
        $DRY_RUN_CMD ${pkgs.uv}/bin/uv tool install 'headroom-ai[all]'
      fi
    '';

    # Run the Headroom optimization proxy as a supervised user service. This is
    # the declarative replacement for `headroom init claude`, which would
    # otherwise scribble an ANTHROPIC_BASE_URL + SessionStart/PreToolUse hooks
    # into ~/.claude/settings.json plus a runtime manifest under headroom's
    # state dir — the hooks exist only to lazily spawn this proxy. A systemd
    # user service supervises it instead. The proxy passes Claude Code's own
    # auth headers straight through to api.anthropic.com (anthropic backend,
    # token mode); no API key is stored here. Upstream is ANTHROPIC_TARGET_API_URL
    # (default api.anthropic.com), NOT ANTHROPIC_BASE_URL, so routing clients at
    # the proxy creates no loop — the empty Environment entry is belt-and-braces.
    # --memory enables persistent cross-session memory (project-scoped by
    # default, seeded at ~/.headroom/memory.db); --no-telemetry opts out of
    # Headroom's anonymous usage telemetry.
    systemd.user.services.headroom-proxy = {
      Unit.Description = "Headroom context-optimization proxy";
      Service = {
        # uv-installed at ~/.local/bin (see installHeadroom above), not a Nix
        # package, so reference by absolute path. %h expands to $HOME.
        ExecStart = "%h/.local/bin/headroom proxy --host 127.0.0.1 --port 8787 --memory --no-telemetry";
        Environment = ["ANTHROPIC_BASE_URL="];
        Restart = "always";
        RestartSec = 2;
      };
      Install.WantedBy = ["default.target"];
    };

    # Exported here rather than via home.sessionVariables: HM only auto-sources
    # its hm-session-vars.sh when programs.zsh integration is on, which it isn't
    # in this setup — so the session var never reached interactive zsh. Routes
    # nh's Anthropic-API clients (Claude Code included) through the proxy. NOTE:
    # this is a hard dependency — if headroom-proxy is down, Claude Code can't
    # reach the API; the service above is Restart=always to keep that window
    # small.
    #
    # Also loads the Grafana MCP service-account token (GRAFANA_SA_TOKEN) for the
    # Velomo prod observability stack. agenix decrypts the token to
    # ~/.config/velomo-grafana-sa.env on framework-13 (owner nh; see
    # hosts/framework-13/secrets.nix); this sources it so the grafana MCP in
    # scraper's .mcp.json gets ${GRAFANA_SA_TOKEN}. Guarded so it's a no-op on
    # machines/hosts where the secret isn't provisioned.
    programs.zsh.initContent = lib.mkOrder 1500 ''
      export ANTHROPIC_BASE_URL="http://127.0.0.1:8787"
      [[ -f ~/.config/velomo-grafana-sa.env ]] && source ~/.config/velomo-grafana-sa.env
    '';
  };
}

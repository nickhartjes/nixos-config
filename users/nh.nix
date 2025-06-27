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
    # To create a user with a hashed password, use the following command:
    # $ nix-shell -p mkpasswd --run 'mkpasswd <password>'
    # In this example, the password is "password"
    initialHashedPassword = "$y$j9T$SWeufZ9NrHX0.d.w72nc20$1zKkVcJHZfIvS5VMqhdP5RwQ7wQHzbsIi.ArDYRXDK7";
    isNormalUser = true;

    ignoreShellProgramCheck = true;
    shell = pkgs.zsh;

    home = "/home/nh";

    description = "nh";
    extraGroups = [
      "wheel" # Allows the user to execute commands with elevated privileges using sudo
      "networkmanager" # Grants permission to manage network connections via NetworkManager
      "libvirtd" # Enables management of virtual machines through libvirt
      "flatpak" # Allows installation and management of Flatpak applications
      "audio" # Provides access to audio devices for sound playback and recording
      "video" # Grants access to video devices like webcams and GPUs
      "plugdev" # Permits mounting and unmounting of removable devices without root privileges
      "input" # Allows interaction with input devices such as keyboards and mice
      "kvm" # Enables usage of hardware virtualization features via KVM
      "qemu-libvirtd" # Associated with QEMU instances managed by libvirt
      "docker" # Docker daemon access
    ];
    openssh.authorizedKeys.keys = [
      "sh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8Fzq/ktI9g9FYsADc8NkaYDhHuXIPPPxwRjXT7Gcwk info@nickhartjes.nl"
    ];
    packages = [
      inputs.home-manager.packages.${pkgs.system}.default
      inputs.agenix.packages.${pkgs.system}.default
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
      inputs.plasma-manager.homeManagerModules.plasma-manager
    ];
    home.stateVersion = "24.11";

    # nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "obsidian"
        "vscode"
        "idea-ultimate"
        "spotify"
        "claude-code"
        "slack"
        "discord"
        "signal-desktop"
        "telegram-desktop"
        "dbeaver-bin"
        "corefonts"
        "terraform"
        "protonvpn-gui"
        "protonvpn-cli"
        "steam"
        "steam-original"
        "steam-unwrapped"
        "lutris"
      ];

    home.packages = with pkgs; [
      fd # A simple, fast and user-friendly alternative to 'find'
      obsidian
      alejandra # A code formatter for various languages
      wl-clipboard # Clipboard management for Wayland
      catppuccin-kde # Catppuccin color scheme for KDE
      just
    ];

    # Add shell aliases for repository management
    home.shellAliases = {
      repo-sync = "~/.local/bin/repo-manager";
      repo-log = "tail -f ~/.local/state/repo-manager.log";
    };

    # KDE Plasma configuration using plasma-manager
    programs.plasma = {
      enable = true;

      # Basic workspace configuration
      workspace = {
        colorScheme = "BreezeDark";
        iconTheme = "breeze-dark";
      };

      # Simple shortcuts
      shortcuts = {
        "kwin"."Switch to Desktop 1" = "Meta+1";
        "kwin"."Switch to Desktop 2" = "Meta+2";
        "kwin"."Switch to Desktop 3" = "Meta+3";
        "kwin"."Switch to Desktop 4" = "Meta+4";
        "kwin"."Window Close" = "Meta+Q,Alt+F4,Close Window";
        "org.freedesktop.krunner.desktop"."_launch" = "Meta";
        "services/org.freedesktop.krunner.desktop"."_launch" = "Meta";
        "services/com.mitchellh.ghostty.desktop"."new-window" = "Meta+Return";
      };

      # Basic configuration files
      configFile = {
        "kdeglobals"."General"."BrowserApplication" = "chromium-browser.desktop";
        "kdeglobals"."General"."TerminalApplication" = "com.github.ghostty";
        "kdeglobals"."General"."TerminalService" = "com.github.ghostty";
        "kwinrc"."Desktops"."Id_1" = "Desktop_1";
        "kwinrc"."Desktops"."Id_2" = "Desktop_2";
        "kwinrc"."Desktops"."Id_3" = "Desktop_3";
        "kwinrc"."Desktops"."Id_4" = "Desktop_4";
        "kwinrc"."Desktops"."Name_1" = "Main";
        "kwinrc"."Desktops"."Name_2" = "Work";
        "kwinrc"."Desktops"."Name_3" = "Media";
        "kwinrc"."Desktops"."Name_4" = "Dev";
        "kwinrc"."Desktops"."Number" = 4;
        "kwinrc"."Desktops"."Rows" = 1;
      };
    };

    components = {
      application = {
        browser = {
          chromium.enable = true;
          firefox.enable = true;
        };
        music = {
          spotify.enable = true;
        };
        ai = {
          claude-code.enable = true;
          ollama.enable = true;
          alpaca.enable = true;
        };
        communication = {
          slack.enable = true;
          discord.enable = true;
          signal.enable = true;
          telegram.enable = true;
        };
        graphics = {
          gimp.enable = true;
          inkscape.enable = true;
        };
        database = {
          dbeaver.enable = true;
          pgadmin.enable = true;
        };
        office = {
          libreoffice.enable = true;
        };
        security = {
          lynis.enable = true;
          protonvpn.enable = true;
        };
        gaming = {
          steam.enable = true;
          lutris.enable = true;
        };
        system = {
          mission-center.enable = true;
        };
      };
      development = {
        editor = {
          vscode.enable = true;
          zed.enable = true;
          intellij.enable = true;
        };
        infrastructure = {
          opentofu.enable = true;
          terraform.enable = true;
          kubernetes.enable = true;
          aws.enable = true;
          k9s.enable = true;
        };
        languages = {
          nodejs.enable = true;
          java.enable = true;
          go.enable = true;
          rust.enable = true;
        };
        git = {
          enable = true;
          userName = "Nick Hartjes";
          userEmail = "nick@hartj.es";
          gpgSigning = {
            enable = true;
            key = "18D6E129BCC96ED3";
          };
        };
      };
      cli = {
        bat.enable = true;
        fastfetch.enable = true;
        fish.enable = true; # Enable fish as well
        fzf.enable = true;
        neofetch.enable = true; # Enable neofetch too
        nh.enable = true;
        zsh.enable = true;
        neovim.enable = true;
        ssh.enable = true;
      };
      terminal = {
        alacritty.enable = true;
        foot.enable = true;
        ghostty.enable = true;
        kitty.enable = true;
        wezterm.enable = true;
      };
      features = {
        desktop = {
          hyprland.enable = false;
          sway.enable = false;
        };
      };
      desktop = {
        fonts.enable = true;
        wayland.enable = false;
      };
      scripts = {
        repoManager = {
          enable = true;
          repositories = {
            users = {
              nh = {
                personal = [
                  "git@github.com:nickhartjes/obsidian.git"
                  "git@github.com:nickhartjes/dotfiles.git"
                  "git@github.com:nickhartjes/nickhartjes.nl.git"
                ];
                projects = [
                  "git@github.com:nickhartjes/talos.git"
                  "git@github.com:nickhartjes/gitops.git"
                  "git@github.com:nickhartjes/codex.git"
                ];
                dealdodo = [
                  "git@github.com:dealdodo/frontend"
                  "git@github.com:dealdodo/backend"
                ];
                entrnce = [
                  "git@github.com:EnergyExchangeEnablersBV/devops-helm-charts.git"
                  "git@github.com:EnergyExchangeEnablersBV/nma-platform.git"
                ];
              };
            };
          };
        };
      };
    };
  };
}

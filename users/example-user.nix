{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  users.users.example = {
    # To create a user with a hashed password, use the following command:
    # $ nix-shell -p mkpasswd --run 'mkpasswd <password>'
    # In this example, the password is "password"
    initialHashedPassword = "$y$j9T$SWeufZ9NrHX0.d.w72nc20$1zKkVcJHZfIvS5VMqhdP5RwQ7wQHzbsIi.ArDYRXDK7";
    isNormalUser = true;

    ignoreShellProgramCheck = true;
    shell = pkgs.zsh;

    description = "example";
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
    ];
    openssh.authorizedKeys.keys = [
      "sh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8Fzq/ktI9g9FYsADc8NkaYDhHuXIPPPxwRjXT7Gcwk info@nickhartjes.nl"
    ];
    packages = [inputs.home-manager.packages.${pkgs.system}.default];
  };

  home-manager.users.example = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      ../components/home-manager
    ];
    home.stateVersion = "24.11";

    # nixpkgs.config.allowUnfree = true;
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "obsidian"
        "vscode"
      ];

    home.packages = with pkgs; [
      bat
      fd

      obsidian
    ];

    components = {
      application = {
        browser = {
          chromium.enable = true;
          firefox.enable = true;
        };
      };
      development = {
        editor = {
          vscode.enable = true;
          zed.enable = true;
        };
      };
      cli = {
        fastfetch.enable = true;
        fish.enable = false;
        fzf.enable = true;
        neofetch.enable = false;
        nh.enable = true;
        zsh.enable = true;
        neovim.enable = true;
      };
      terminal = {
        alacritty.enable = true;
        foot.enable = true;
        ghostty.enable = true;
        kitty.enable = true;
        wezterm.enable = true;
      };
    };

    programs.git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your@email.com";
    };
  };
}

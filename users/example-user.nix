{
  config,
  pkgs,
  inputs,
  ...
}: {
  users.users.example = {
    # To create a user with a hashed password, use the following command:
    # $ nix-shell -p mkpasswd --run 'mkpasswd <password>'
    # In this example, the password is "password"
    initialHashedPassword = "$y$j9T$SWeufZ9NrHX0.d.w72nc20$1zKkVcJHZfIvS5VMqhdP5RwQ7wQHzbsIi.ArDYRXDK7";
    isNormalUser = true;
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
      ../modules/home-manager
    ];
    home.stateVersion = "24.11";
    home.packages = with pkgs; [
      bat
      fd
    ];

    features = {
      cli = {
        fish.enable = true;
        fzf.enable = true;
        neofetch.enable = true;
      };
    };

    programs.git = {
      enable = true;
      userName = "Your Name";
      userEmail = "your@email.com";
    };
  };
}

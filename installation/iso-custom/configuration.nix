{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];

  # boot.loader.grub = {
  #   enable = true;
  #   device = "/dev/vda";
  # };

  # Enable X server and Plasma 6 desktop environment
  # services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable SDDM
  services.displayManager.sddm.enable = true;

  # Define the "nixos" user
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"]; # "wheel" for sudo, "networkmanager" for networking
    # No password: this image boots on networks you don't control. Log in with
    # the framework-13 keys (kept in sync with secrets/secrets.nix).
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Passwordless sudo for wheel: login is key-only, so this needs a key.
  security.sudo.wheelNeedsPassword = false;

  # Install essential packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Enable networking with NetworkManager
  networking.networkmanager.enable = true;

  # Set the time zone (optional)
  time.timeZone = "UTC";

  # Specify the system state version
  system.stateVersion = "25.05";
}

{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: {
  # ---- Bootloader ----
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- Nixpkgs (from common, minus what we don't need) ----
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  # ---- Nix daemon (from common) ----
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = ["root"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (flakeName: _: "${flakeName}=flake:${flakeName}") flakeInputs;
  };

  # ---- Identity ----
  networking.hostName = "velomo-alpha";
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- Networking ----
  networking.networkmanager.enable = true;

  # ---- Tailscale (autoconnect added in Phase 2 once auth-key secret exists) ----
  services.tailscale.enable = true;

  # ---- SSH ----
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # ---- User: inline nh definition (see spec: Server-vs-Workstation User Split) ----
  # NOTE: do NOT import users/nh.nix here. The workstation tree assumes
  # framework-13 keys and a full home-manager profile.
  users.users.nh = {
    isNormalUser = true;
    description = "nh";
    home = "/home/nh";
    # Allow first-time console login if SSH key access fails; remove later if desired.
    initialHashedPassword = "$y$j9T$SWeufZ9NrHX0.d.w72nc20$1zKkVcJHZfIvS5VMqhdP5RwQ7wQHzbsIi.ArDYRXDK7";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      # framework-13 SSH key — copied verbatim from users/nh.nix
      "sh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII8Fzq/ktI9g9FYsADc8NkaYDhHuXIPPPxwRjXT7Gcwk info@nickhartjes.nl"
    ];
    shell = pkgs.bash;
  };

  # ---- Minimal system packages ----
  environment.systemPackages = with pkgs; [
    git
    neovim
    htop
  ];

  # ---- Firewall ----
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedTCPPorts = [22];
    interfaces.tailscale0.allowedTCPPorts = [9120];
  };

  # ---- stateVersion: pin to the release the host was first installed against ----
  system.stateVersion = "25.05";
}

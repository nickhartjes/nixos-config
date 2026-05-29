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
      trusted-users = ["root" "@wheel"];
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

  # ---- Tailscale ----
  services.tailscale.enable = true;

  systemd.services.tailscale-autoconnect = {
    description = "Authenticate Tailscale on first boot";
    after = ["network-pre.target" "tailscaled.service"];
    wants = ["network-pre.target" "tailscaled.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      sleep 2
      status=$(${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r .BackendState)
      if [ "$status" = "Running" ]; then
        exit 0
      fi
      ${pkgs.tailscale}/bin/tailscale up \
        --authkey "file:${config.age.secrets."velomo-alpha/tailscale-authkey".path}" \
        --ssh
    '';
  };

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
      # framework-13 keys — kept in sync with secrets/secrets.nix
      # (framework-13 and framework-13-2). The "info@nickhartjes.nl" key that
      # used to live here was a stale entry copied from users/nh.nix and did
      # not match any private key actually held on the framework-13.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
    ];
    shell = pkgs.bash;
  };

  # ---- Minimal system packages ----
  environment.systemPackages = with pkgs; [
    git
    neovim
    htop
    jq
    tailscale
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

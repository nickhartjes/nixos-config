{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: {
  # ---- Bootloader: UEFI with Secure Boot disabled, so plain systemd-boot.
  # Deliberately NOT lanzaboote (framework-13 needs it; this host does not).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- Nixpkgs. allowUnfree is required for claude-code.
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  # ---- Nix daemon (same shape as velomo-alpha)
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

  # ---- Identity
  networking.hostName = "n100-nanoclaw";
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- Networking
  networking.networkmanager.enable = true;

  # ---- Tailscale.
  # Inlined on purpose: components.system.tailscale drags in trayscale (a GTK4
  # tray GUI) and a graphical-session user unit, which is wrong for a headless
  # host. velomo-alpha inlines it for the same reason.
  services.tailscale.enable = true;

  # DEVIATION FROM SPEC: no tailscale-autoconnect oneshot. The spec calls for
  # velomo-alpha's unit, but that unit reads a tailscale-authkey agenix secret
  # the spec never lists — the spec is self-inconsistent there. Since this host
  # already needs a hands-on session for `claude login` and two OAuth flows, one
  # `tailscale up --ssh` costs nothing and removes an authkey secret from the
  # design. Revisit if this host is ever rebuilt unattended.

  # ---- SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # ---- User nh, defined inline.
  # Do NOT import users/nh.nix: it assumes framework-13's keys and a full
  # home-manager profile. Same reasoning as velomo-alpha.
  users.users.nh = {
    isNormalUser = true;
    description = "nh";
    home = "/home/nh";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      # framework-13 user keys, kept in sync with secrets/secrets.nix
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
    ];
    shell = pkgs.bash;
  };

  # ---- Packages: the nanoclaw toolchain plus basic operator tools.
  # Upstream asks for pnpm 10+; nixpkgs ships 11.21.0.
  environment.systemPackages = with pkgs; [
    nodejs_22
    pnpm
    bun
    claude-code
    git
    jq
    htop
    neovim
    tailscale
  ];

  # ---- Firewall. nanoclaw needs no inbound ports: it dials out to Telegram.
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedTCPPorts = [22];
  };

  # ---- stateVersion: the release this host was first installed against.
  system.stateVersion = "26.11";
}

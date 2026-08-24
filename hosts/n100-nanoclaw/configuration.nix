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
  # /boot is 512 MiB and each generation costs ~56 MiB (43 MiB of that initrd),
  # so cap retained entries well under what would fill the ESP.
  boot.loader.systemd-boot.configurationLimit = 5;

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
      # Matches hosts/velomo-alpha. nh is already root-equivalent on this
      # host via the docker group, so this isn't a hard security boundary —
      # the password-sudo requirement below is about fleet parity, not
      # gatekeeping nix builds.
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

  # nanoclaw's installer drops a prebuilt, dynamically-linked generic-Linux
  # binary at ~/.local/bin/onecli (its credential vault). NixOS ships only a
  # stub /lib64/ld-linux-x86-64.so.2, so such binaries cannot run without
  # nix-ld providing a real loader and a library path. The installer
  # misreports this as a PATH problem. Library list mirrors
  # hosts/common/default.nix, which this host does not import.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      zstd
      openssl
      curl
      libxml2
      libxslt
      libgcrypt
      icu
      ncurses
      readline
      bzip2
      xz
      sqlite
      libffi
    ];
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
    # Allow first-time console login if SSH key access fails; remove later if desired.
    # Same hash as velomo-alpha so both headless hosts share one console fallback.
    initialHashedPassword = "$y$j9T$SWeufZ9NrHX0.d.w72nc20$1zKkVcJHZfIvS5VMqhdP5RwQ7wQHzbsIi.ArDYRXDK7";
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

  # agenix creates the parent directories for its `path =` overrides (see
  # secrets.nix) with mkdir -p as root during activation, which leaves
  # /home/nh/.config and /home/nh/.ssh owned root:root and unwritable by nh.
  # framework-13 never hits this because both dirs already exist there. Without
  # these rules nh cannot create ~/.ssh/known_hosts, which makes the obsidian
  # deploy key unusable non-interactively. tmpfiles runs after activation
  # scripts, so it corrects the ownership agenix leaves behind.
  systemd.tmpfiles.rules = [
    "d /home/nh/.config 0755 nh users - -"
    "d /home/nh/.ssh 0700 nh users - -"
    # nanoclaw spawns `/bin/bash` in 24 places (e.g. setup/lib/skill-driver.ts
    # sets `shell: '/bin/bash'`), and its /add-<channel> skills shell out the
    # same way. NixOS ships only /bin/sh, so every one dies with ENOENT —
    # which surfaces as "engine could not apply (spawnSync /bin/bash ENOENT)".
    # Patching 24 call sites in the fork would conflict on every upstream
    # merge; one symlink covers all of them and anything added later.
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

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

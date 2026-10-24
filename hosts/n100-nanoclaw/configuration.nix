{
  config,
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: let
  # nanoclaw's installer names its systemd --user unit
  # "nanoclaw-v2-<8 hex chars>"; the hex suffix is generated fresh by the
  # installer (it's not derived from anything stable on this host) and is
  # NOT guaranteed to survive a reinstall. This value was read off the live
  # host on 2026-08-24. If nanoclaw is ever reinstalled, find the new name
  # with `systemctl --user list-units 'nanoclaw-v2-*'` (as nh) and update
  # this constant — otherwise the drop-in below silently targets a unit
  # that no longer exists and the PATH crash-loop this fixes comes back.
  nanoclawUnitName = "nanoclaw-v2-3b88d860";
in {
  # ---- Bootloader: UEFI with Secure Boot disabled, so plain systemd-boot.
  # Deliberately NOT lanzaboote (framework-13 needs it; this host does not).
  boot.loader.systemd-boot.enable = true;
  # The boot-menu editor allows init=/bin/sh, i.e. root from the console.
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;
  # /boot is 512 MiB and each generation costs ~56 MiB (43 MiB of that initrd),
  # so cap retained entries well under what would fill the ESP.
  boot.loader.systemd-boot.configurationLimit = 5;

  # ---- Nixpkgs. allowUnfree is required for claude-code.
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  # ---- Nix daemon (same shape as velomo-alpha)
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      # Not @wheel, matching velomo-alpha: `just deploy` copies closures
      # signed with framework-13's key (/etc/nix/signing-key there). nh is
      # still root-equivalent here via docker (see extraGroups), so this is
      # fleet parity rather than a hard boundary on this host.
      trusted-users = ["root"];
      extra-trusted-public-keys = ["framework-13-1:yGXpwLATK5IztqdI0ssqoKAgxsrxQ20E3s99X8TQf7w="];
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
  services.tailscale = {
    enable = true;
    # Tailscale SSH bypasses sshd (PermitRootLogin, keys, sudo). RunSSH is
    # persisted from the manual `tailscale up --ssh`, so clear it on every start.
    extraSetFlags = ["--ssh=false"];
  };

  # DEVIATION FROM SPEC: no tailscale-autoconnect oneshot. The spec calls for
  # velomo-alpha's unit, but that unit reads a tailscale-authkey agenix secret
  # the spec never lists — the spec is self-inconsistent there. Since this host
  # already needs a hands-on session for `claude login` and two OAuth flows, one
  # `tailscale up` costs nothing and removes an authkey secret from the
  # design. Revisit if this host is ever rebuilt unattended.

  # ---- SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      # With UsePAM, keyboard-interactive still accepts the account password.
      KbdInteractiveAuthentication = false;
    };
  };

  # sudo authenticates against the forwarded SSH agent, checked against the
  # root-owned /etc/ssh/authorized_keys.d/nh. No password needed for deploys.
  # This is not a boundary against nanoclaw: nh is in docker (root without
  # sudo), and during a deploy anything running as nh can use the forwarded
  # agent. framework-13 adds the keys with confirm-on-use (ssh-add -c), so
  # each signature needs an approval there.
  security.pam.sshAgentAuth.enable = true;

  # ---- User nh, defined inline.
  # Do NOT import users/nh.nix: it assumes framework-13's keys and a full
  # home-manager profile. Same reasoning as velomo-alpha.
  users.users.nh = {
    isNormalUser = true;
    description = "nh";
    home = "/home/nh";
    # No password in the repo: it is public. Set the console fallback with
    # `passwd` on the host (or `nixos-enter` at install time).
    extraGroups = [
      "wheel"
      "networkmanager"
      # EXCEPTION: docker is root-equivalent, but nanoclaw runs as nh and
      # starts its agent containers through the daemon. Remove once nanoclaw
      # runs as its own user with rootless docker.
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
    "d /home/nh/.config/nanoclaw 0755 nh users - -"
    "d /home/nh/.config/traders 0700 nh users - -"
    # nanoclaw refuses every additional container mount unless the host path
    # is listed in mount-allowlist.json (matched against the *resolved*
    # realPath). Without it, credentials (the Anthropic auth token, the Hevy
    # MCP key, google-health-mcp's OAuth tokens, the training-vault deploy
    # key) are silently rejected and never reach agent containers.
    #
    # This is a one-time seed via tmpfiles' `C` type, not a fully managed
    # file: `C` copies the argument path only if the destination doesn't
    # already exist, so a from-scratch install boots with a working
    # allowlist but this module never fights `ncl` or a by-hand edit adding
    # a mount later. A read-only symlink into the store was considered and
    # rejected — operators edit this file at runtime (jq or by hand), and a
    # store symlink would turn every such edit into an EROFS failure, which
    # is worse than the missing-mount bug being fixed here. Content mirrors
    # what was live on the host on 2026-08-24; re-sync the seed in
    # environment.etc below if a permanent mount is added later and you want
    # a bare-metal reinstall to come back up with it already present.
    "C /home/nh/.config/nanoclaw/mount-allowlist.json 0644 nh users - /etc/nanoclaw/mount-allowlist.seed.json"
  ];

  # Seed content for the tmpfiles `C` rule above.
  environment.etc."nanoclaw/mount-allowlist.seed.json".text = ''
    {
      "allowedRoots": [
        {
          "path": "/home/nh/.config/nanoclaw-anthropic-token",
          "allowReadWrite": false,
          "description": "Anthropic auth token, mounted by reference for the direct gateway provider"
        },
        {
          "path": "/home/nh/.config/hevy-mcp.env",
          "allowReadWrite": false,
          "description": "Hevy API key (agenix) for the hevy MCP server"
        },
        {
          "path": "/home/nh/.google-health-mcp",
          "allowReadWrite": true,
          "description": "google-health-mcp OAuth config + tokens; rw so token refresh persists"
        },
        {
          "path": "/home/nh/.ssh/id_training",
          "allowReadWrite": false,
          "description": "deploy key for the private training vault repo"
        }
      ],
      "blockedPatterns": []
    }
  '';

  # ---- nanoclaw systemd --user unit: fix its PATH.
  #
  # nanoclaw's installer writes
  # ~/.config/systemd/user/${nanoclawUnitName}.service itself, with
  # `Environment=PATH=/usr/local/bin:/usr/bin:/bin:/home/nh/.local/bin` baked
  # in for a generic Linux distro. NixOS puts docker, git, bun and node
  # nowhere on that PATH, so nanoclaw's ensureDockerRunning() can't find the
  # `docker` binary and the service crash-loops with "Container runtime
  # failed to start".
  #
  # Mechanism: overrideStrategy = "asDropin" makes NixOS write only a
  # drop-in (/etc/systemd/user/${nanoclawUnitName}.service.d/overrides.conf)
  # instead of a full replacement unit, so it overrides just PATH and leaves
  # everything else the installer writes (ExecStart, WorkingDirectory, log
  # paths, restart policy, ...) untouched. That's what makes this survive
  # the installer rewriting its unit on every nanoclaw upgrade — the
  # alternative (editing the generated unit file directly) would be undone
  # on the next reinstall. This mirrors the hand-applied fix that was live
  # on this host before this file existed, at
  # ~/.config/systemd/user/${nanoclawUnitName}.service.d/10-nixos-path.conf.
  #
  # The unit *name* itself still has to be known (see nanoclawUnitName
  # above) — there's no name-independent way to attach a drop-in to one
  # specific unit.
  systemd.user.services.${nanoclawUnitName} = {
    overrideStrategy = "asDropin";
    serviceConfig.Environment = "PATH=/run/current-system/sw/bin:/home/nh/.local/bin:/usr/bin:/bin";
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
    # traders: CLI for manual imports/runs, age to decrypt traders-data imports
    config.services.traders.package
    age
  ];

  # ---- traders: daily market digest into the nanoclaw Telegram chat.
  # Data: ~/traders-data (private git, pulled before each run with a read-only
  # deploy key); state: ~/traders-state. Runs Tue..Sat 07:30 Europe/Amsterdam;
  # see the traders repo docs/deploy.md.
  services.traders = {
    enable = true;
    environmentFile = config.age.secrets."n100-nanoclaw/traders-telegram.env".path;
    timer = true;
  };
  systemd.services.traders-digest.environment.GIT_SSH_COMMAND =
    "ssh -i /home/nh/.ssh/id_traders_data -o IdentitiesOnly=yes";
  # GitHub's ed25519 host key, from https://api.github.com/meta (2026-10-24).
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # ---- Firewall. nanoclaw needs no inbound ports: it dials out to Telegram.
  networking.firewall = {
    enable = true;
    # tailscale0 is not trusted: tailnet nodes get only SSH, like the LAN.
    allowedTCPPorts = [22];
  };

  # ---- stateVersion: the release this host was first installed against.
  system.stateVersion = "26.11";
}

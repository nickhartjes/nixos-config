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
  # The boot-menu editor allows init=/bin/sh, i.e. root from the console.
  boot.loader.systemd-boot.editor = false;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---- Nixpkgs (from common, minus what we don't need) ----
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };

  # ---- Nix daemon (from common) ----
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      # Not @wheel: a trusted user can set any nix.conf option per call, which
      # is root. `just deploy` copies closures signed with framework-13's key
      # (/etc/nix/signing-key there), so nh doesn't need to be trusted.
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

  # ---- Identity ----
  networking.hostName = "velomo-alpha";
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- Networking ----
  networking.networkmanager.enable = true;

  # Host DNS must NOT depend on Tailscale. With MagicDNS taking over
  # /etc/resolv.conf and no global nameservers pushed by the tailnet, tailscaled
  # has no upstream ("dns: resolver: forward: no upstream resolvers set,
  # returning SERVFAIL") and every non-tailnet lookup fails. That silently
  # stopped all scraper crawls from 2026-09-09 (name resolution errors).
  # Static public resolvers keep the crawler working even if tailnet DNS
  # config changes. Side effect: *.ts.net names do not resolve on this host.
  networking.nameservers = ["1.1.1.1" "9.9.9.9"];

  # ---- Tailscale ----
  services.tailscale = {
    enable = true;
    # Do not let tailscaled rewrite /etc/resolv.conf (see networking.nameservers).
    # --ssh=false: Tailscale SSH bypasses sshd (PermitRootLogin, keys, sudo).
    # RunSSH is persisted in tailscaled's prefs, so it has to be cleared with
    # `tailscale set` on every start, not just left out of `tailscale up`.
    extraSetFlags = ["--accept-dns=false" "--ssh=false"];
  };

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
        --accept-dns=false
    '';
  };

  # ---- SSH ----
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
  # While a deploy runs, anything running as nh here can use the forwarded
  # agent too; framework-13 adds the keys with confirm-on-use (ssh-add -c), so
  # each signature needs an approval there.
  security.pam.sshAgentAuth.enable = true;

  # ---- User: inline nh definition (see spec: Server-vs-Workstation User Split) ----
  # NOTE: do NOT import users/nh.nix here. The workstation tree assumes
  # framework-13 keys and a full home-manager profile.
  users.users.nh = {
    isNormalUser = true;
    description = "nh";
    home = "/home/nh";
    # No password in the repo: it is public. Set the console fallback with
    # `passwd` on the host (or `nixos-enter` at install time).
    extraGroups = [
      "wheel"
      "networkmanager"
      # Not docker: the docker group is root without sudo. doco-cd, the
      # runners and pg-backup talk to the daemon as root or via their own
      # group membership; nh uses `sudo docker`.
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
    # tailscale0 is not trusted: every tailnet node (n100-nanoclaw included)
    # gets only the ports listed here. 22 is open on all interfaces.
    allowedTCPPorts = [22];
    # 3300: Grafana, bound to the tailnet IP only.
    interfaces.tailscale0.allowedTCPPorts = [3300];
    # Docker-published ports bypass this firewall (DNAT runs first). The
    # docker component binds them to 127.0.0.1 unless a mapping names an IP.
  };

  # ---- stateVersion: pin to the release the host was first installed against ----
  system.stateVersion = "26.05";
}

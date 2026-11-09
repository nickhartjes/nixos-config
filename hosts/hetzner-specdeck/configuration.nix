{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # Hetzner Cloud VM (2 vCPU, 4 GB) in fsn1. Runs SpecDeck's sharing service:
  # the TURN relay (coturn, below) and the server behind a Cloudflare tunnel
  # (specdeck.nix). It moved here from n100-nanoclaw, which sits behind
  # DELTA's CGNAT. turn.hartj.es points here (DNS only).
  publicIp = "2.31.128.103";
  publicIp6 = "2a01:4f8:c17:4b8d::1";
  turnPort = 3478;
  # No NAT in front of this host, so the relay range need not match any port
  # forward; coturn's default range. Each relayed viewer uses one or two.
  relayMin = 49152;
  relayMax = 65535;
in {
  # ---- Bootloader: Hetzner Cloud x86 boots legacy BIOS. disko fills in
  # grub.devices from the EF02 partition.
  boot.loader.grub.enable = true;
  boot.loader.grub.configurationLimit = 5;

  # ---- Nix daemon (same shape as n100-nanoclaw)
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      # `just deploy` copies closures signed with framework-13's key.
      trusted-users = ["root"];
      extra-trusted-public-keys = ["framework-13-1:yGXpwLATK5IztqdI0ssqoKAgxsrxQ20E3s99X8TQf7w="];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (flakeName: _: "${flakeName}=flake:${flakeName}") flakeInputs;
  };

  # ---- Identity
  networking.hostName = "hetzner-specdeck";
  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # ---- Networking: IPv4 by DHCP; Hetzner Cloud gives IPv6 only as a static
  # /64 with the gateway at fe80::1.
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "en* eth*";
    networkConfig.DHCP = "ipv4";
    address = ["${publicIp6}/64"];
    routes = [{Gateway = "fe80::1";}];
  };

  # ---- Tailscale, inlined for the same reasons as n100-nanoclaw. Join once
  # by hand with `sudo tailscale up`; `just deploy hetzner-specdeck` reaches
  # the host by its tailnet name after that.
  services.tailscale = {
    enable = true;
    extraSetFlags = ["--ssh=false"];
  };

  # ---- SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # sudo authenticates against the forwarded SSH agent, as on n100-nanoclaw.
  security.pam.sshAgentAuth.enable = true;

  users.users.nh = {
    isNormalUser = true;
    description = "nh";
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      # framework-13 user keys, kept in sync with secrets/secrets.nix
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
    ];
    shell = pkgs.bash;
  };

  # ---- coturn: SpecDeck's TURN relay. UDP only: the app's WebRTC library
  # (libdatachannel/libjuice) has no TURN over TCP or TLS.
  services.coturn = {
    enable = true;
    listening-port = turnPort;
    listening-ips = [publicIp];
    relay-ips = [publicIp];
    min-port = relayMin;
    max-port = relayMax;
    realm = "specdeck";
    # Credentials come from the signalling service (TURN REST API scheme).
    use-auth-secret = true;
    static-auth-secret-file = config.age.secrets."hetzner-specdeck/specdeck-turn-secret".path;
    no-cli = true;
    no-tcp = true;
    no-tls = true;
    no-dtls = true;
    no-tcp-relay = true;
    extraConfig = ''
      fingerprint
      no-multicast-peers
      # Never relay into private networks (Hetzner's metadata service and
      # private networks included). Same list as deploy/k8s/base/coturn.yaml.
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=169.254.0.0-169.254.255.255
      denied-peer-ip=100.64.0.0-100.127.255.255
    '';
  };

  # ---- Firewall: SSH, plus TURN and its relay ports.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
    allowedUDPPorts = [turnPort];
    allowedUDPPortRanges = [
      {
        from = relayMin;
        to = relayMax;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    htop
    neovim
  ];

  system.stateVersion = "26.11";
}

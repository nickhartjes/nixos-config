{pkgs, ...}: {
  # Deliberately independent of hosts/common: WSL needs neither bootloader,
  # desktop services nor the workstation's secrets and complete application set.
  wsl.enable = true;
  wsl.defaultUser = "nh";
  # GPU via the Windows driver (/usr/lib/wsl/lib) for Mesa d3d12/dzn.
  wsl.useWindowsDriver = true;
  hardware.graphics.enable = true;
  networking.hostName = "wsl-t3";
  system.stateVersion = "26.05";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  services.tailscale = {
    enable = true;
    # Use OpenSSH and the repository's SSH-agent sudo authentication.
    extraSetFlags = ["--ssh=false"];
  };
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [22];
  security.pam.sshAgentAuth.enable = true;

  virtualisation.docker.enable = true;

  # Same secret and path as framework-13 (users/nh/secrets.nix); decrypted with
  # this host's SSH host key, the agenix default when openssh is enabled.
  age.secrets.video-upload-client = {
    file = ../../secrets/nh/video-upload-client.age;
    mode = "400";
    owner = "nh";
    group = "users";
  };

  users.users.nh = {
    # T3 agents run as nh and may build/run project containers.
    extraGroups = ["docker" "video"];
    linger = true;
    openssh.authorizedKeys.keys = [
      # Framework keys, matching the other deployment targets.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
    ];
  };
  # GitHub's ed25519 host key, from https://api.github.com/meta (2026-11-19).
  # Without it, SSH clones fail with "Host key verification failed".
  programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  programs.git.enable = true;
  programs.nix-ld.enable = true;

  # Only the text-to-speech key (the videos are voiced here); decrypted with
  # this host's SSH key, to the same path as on the Framework (users/nh/secrets.nix).
  age.identityPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  age.secrets.tts-key = {
    file = ../../secrets/nh/tts-key.age;
    path = "/home/nh/.config/tts/key";
    mode = "400";
    owner = "nh";
    group = "users";
  };
  # Instagram API system-user token for posting the channel's Reels.
  age.secrets.instagram-token = {
    file = ../../secrets/nh/instagram-token.age;
    path = "/home/nh/.config/instagram/token";
    mode = "400";
    owner = "nh";
    group = "users";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nh = {
      imports = [../../components/home-manager/application/ai/t3code.nix];
      home.stateVersion = "26.05";
      home.packages = with pkgs; [codex claude-code ripgrep];
      # GitHub over HTTPS with gh's token: no private key lives here, and the
      # Framework's agent is never forwarded (see the deploy recipe in justfile).
      programs.git = {
        enable = true;
        # Same identity as components.development.git on the Framework.
        settings.user = {
          name = "Nick Hartjes";
          email = "nick@hartj.es";
        };
      };
      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        settings.git_protocol = "https";
      };
      # Not via components.cli.nh: that hardcodes ~/.config/nixos-config, and
      # this host keeps the flake in /etc/nixos-config.
      programs.nh = {
        enable = true;
        flake = "/etc/nixos-config";
        clean = {
          enable = true;
          extraArgs = "--keep 5 --keep-since 3d";
        };
      };
      components.application.ai.t3code = {
        enable = true;
        server.enable = true;
      };
    };
  };
}

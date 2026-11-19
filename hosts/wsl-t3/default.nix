{pkgs, ...}: {
  # Deliberately independent of hosts/common: WSL needs neither bootloader,
  # desktop services nor the workstation's secrets and complete application set.
  wsl.enable = true;
  wsl.defaultUser = "nh";
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

  users.users.nh = {
    linger = true;
    openssh.authorizedKeys.keys = [
      # Framework keys, matching the other deployment targets.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es"
    ];
  };
  programs.git.enable = true;
  programs.nix-ld.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nh = {
      imports = [../../components/home-manager/application/ai/t3code.nix];
      home.stateVersion = "26.05";
      home.packages = with pkgs; [codex claude-code gh ripgrep];
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

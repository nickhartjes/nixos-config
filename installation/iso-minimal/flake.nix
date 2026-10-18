{
  description = "Minimal NixOS installation media";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: {
    nixosConfigurations = {
      installationIso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({
            pkgs,
            modulesPath,
            ...
          }: {
            imports = [
              (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
            ];

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
          })
        ];
      };
    };
  };
}

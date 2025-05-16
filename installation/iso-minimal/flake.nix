{
  description = "Minimal NixOS installation media";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
              initialPassword = "nixos"; # Default password (changeable on first login)
            };

            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PasswordAuthentication = true;
              };
            };

            # Allow passwordless sudo for the "wheel" group
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

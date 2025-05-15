{
  description = "Minimal NixOS installation media";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = {
    self,
    nixpkgs,
  }: {
    nixosConfigurations.installationIso = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        (
          {
            pkgs,
            modulesPath,
            ...
          }: let
            inherit (pkgs) neovim git;
          in {
            imports = [
              (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
            ];

            environment.systemPackages = with pkgs; [
              neovim
              git
            ];

            users.users.nh = {
              isNormalUser = true;
              password = "nixos"; # plaintext, after the installation everything wil be overwritten
              extraGroups = ["wheel"]; # sudo access
            };

            services.openssh.enable = true;
            services.openssh.settings.PermitRootLogin = "yes";
            services.openssh.settings.PasswordAuthentication = true;

            # Optionally, allow passwordless sudo for wheel group
            security.sudo.wheelNeedsPassword = false;
          }
        )
      ];
    };
  };
}

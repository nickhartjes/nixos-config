{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    nixos-generators,
    ...
  }: {
    packages.x86_64-linux = {
      # For a full list of available formats, see:
      # https://github.com/nix-community/nixos-generators

      vmware = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "vmware";

        # optional arguments:
        # explicit nixpkgs and lib:
        # pkgs = nixpkgs.legacyPackages.x86_64-linux;
        # lib = nixpkgs.legacyPackages.x86_64-linux.lib;
        # additional arguments to pass to modules:
        # specialArgs = { myExtraArg = "foobar"; };

        # you can also define your own custom formats
        # customFormats = { "myFormat" = <myFormatModule>; ... };
        # format = "myFormat";
      };
      vbox = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "virtualbox";
      };
      iso = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "iso";
      };
      hyperv = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "hyperv";
      };
      qcow = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
        ];
        format = "qcow";
      };
    };
  };
}

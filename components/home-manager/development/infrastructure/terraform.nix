{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.infrastructure.terraform = {
    enable = lib.mkEnableOption "Terraform infrastructure as code tool";
  };

  config = lib.mkIf config.components.development.infrastructure.terraform.enable {
    # terraform is BSL-licensed (unfree), so cache.nixos.org never has it and it
    # is compiled locally on every nixpkgs bump. Skip its long Go test suite.
    home.packages = [
      (pkgs.terraform.overrideAttrs {doCheck = false;})
    ];
  };
}

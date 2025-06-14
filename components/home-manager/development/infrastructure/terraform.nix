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
    home.packages = with pkgs; [
      terraform
    ];

    # Add terraform to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "terraform"
      ];
  };
}

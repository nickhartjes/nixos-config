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

  };
}

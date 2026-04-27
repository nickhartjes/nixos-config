{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.infrastructure.aws = {
    enable = lib.mkEnableOption "AWS development tools";
  };

  config = lib.mkIf config.components.development.infrastructure.aws.enable {
    home.packages = with pkgs; [
      awscli2 # AWS Command Line Interface v2
      aws-cdk-cli # AWS Cloud Development Kit
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.infrastructure.opentofu = {
    enable = lib.mkEnableOption "OpenTofu infrastructure as code tool";
  };

  config = lib.mkIf config.components.development.infrastructure.opentofu.enable {
    home.packages = with pkgs; [
      opentofu
    ];

    # OpenTofu is free software, no need for allowUnfreePredicate
  };
}

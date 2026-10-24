{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.ai.orca = {
    enable = lib.mkEnableOption "Orca agent development environment";
  };

  config = lib.mkIf config.components.application.ai.orca.enable {
    home.packages = [
      (pkgs.callPackage ../../../../pkgs/orca-ide {})
    ];
  };
}

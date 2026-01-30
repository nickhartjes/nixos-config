{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.database.pgmodeler = {
    enable = lib.mkEnableOption "pgModeler PostgreSQL database modeler";
  };

  config = lib.mkIf config.components.application.database.pgmodeler.enable {
    home.packages = with pkgs; [
      pgmodeler
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.database.pgadmin = {
    enable = lib.mkEnableOption "pgAdmin4 PostgreSQL administration tool";
  };

  config = lib.mkIf config.components.application.database.pgadmin.enable {
    home.packages = with pkgs; [
      pgadmin4-desktopmode
    ];

    # pgAdmin4 is free software, no need for allowUnfreePredicate
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.database.dbeaver = {
    enable = lib.mkEnableOption "DBeaver database tool";
  };

  config = lib.mkIf config.components.application.database.dbeaver.enable {
    home.packages = with pkgs; [
      dbeaver-bin
    ];

    # Add dbeaver-bin to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "dbeaver-bin"
      ];
  };
}

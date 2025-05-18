{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.components.cli.nh;
in {
  options.components.cli.nh.enable = mkEnableOption "enable nh";

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 3d";
      };
    };
  };
}

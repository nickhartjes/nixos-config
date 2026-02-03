{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.office.anytype = {
    enable = lib.mkEnableOption "Anytype - P2P note-taking tool";
  };

  config = lib.mkIf config.components.application.office.anytype.enable {
    home.packages = with pkgs; [
      anytype
    ];
  };
}
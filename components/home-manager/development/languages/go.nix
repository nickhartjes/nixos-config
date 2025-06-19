{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.languages.go = {
    enable = lib.mkEnableOption "Go development environment";
  };

  config = lib.mkIf config.components.development.languages.go.enable {
    home.packages = with pkgs; [
      go # go language
      air # live reload
      delve # go debugger
      gdlv # gui for go debugger
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.languages.nix = {
    enable = lib.mkEnableOption "Nix language tools and formatter";
  };

  config = lib.mkIf config.components.development.languages.nix.enable {
    home.packages = with pkgs; [
      alejandra
    ];
  };
}

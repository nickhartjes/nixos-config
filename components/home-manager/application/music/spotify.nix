{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.music.spotify = {
    enable = lib.mkEnableOption "Spotify music player";
  };

  config = lib.mkIf config.components.application.music.spotify.enable {
    home.packages = with pkgs; [
      spotify
    ];

    # Add spotify to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "spotify"
      ];
  };
}

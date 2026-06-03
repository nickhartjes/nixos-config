{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.languages.java = {
    enable = lib.mkEnableOption "Java development environment";
  };

  # JDKs are installed via mise (see components/.../mise.nix); IntelliJ
  # finds them under ~/.local/share/mise/installs/java/. Only build tooling
  # lives here.
  config = lib.mkIf config.components.development.languages.java.enable {
    home.packages = with pkgs; [
      gradle
    ];
  };
}

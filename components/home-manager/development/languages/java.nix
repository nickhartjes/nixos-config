{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.languages.java = {
    enable = lib.mkEnableOption "Java development environment";
  };

  config = lib.mkIf config.components.development.languages.java.enable {
    home.packages = with pkgs; [
      gradle
    ];

    programs = {
      java = {
        enable = true;
        package = pkgs.jdk21;
      };
    };

    home.file.".jdks/jdk11" = {
      source = pkgs.jdk11;
    };

    home.file.".jdks/jdk17" = {
      source = pkgs.jdk17;
    };

    home.file.".jdks/jdk21" = {
      source = pkgs.jdk21;
    };

    home.file.".jdks/jdk23" = {
      source = pkgs.jdk23;
    };

    home.file.".jdks/jetbrains-jdk" = {
      source = pkgs.jetbrains.jdk;
    };
  };
}

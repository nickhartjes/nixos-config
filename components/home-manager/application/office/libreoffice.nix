{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.office.libreoffice = {
    enable = lib.mkEnableOption "LibreOffice office suite with extra fonts";
  };

  config = lib.mkIf config.components.application.office.libreoffice.enable {
    home.packages = with pkgs; [
      libreoffice
      corefonts # Microsoft core fonts for better compatibility
    ];

  };
}

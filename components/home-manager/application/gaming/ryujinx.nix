{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.gaming.ryujinx = {
    enable = lib.mkEnableOption "Ryujinx gaming emulator";
  };

  config = lib.mkIf config.components.application.gaming.ryujinx.enable {
    home.packages = with pkgs; [
      ryujinx
    ];
  };
}

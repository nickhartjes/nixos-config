{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.communication.telegram = {
    enable = lib.mkEnableOption "Telegram instant messaging client";
  };

  config = lib.mkIf config.components.application.communication.telegram.enable {
    home.packages = with pkgs; [
      telegram-desktop
    ];

  };
}

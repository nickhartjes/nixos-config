{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.communication.discord = {
    enable = lib.mkEnableOption "Discord communication platform";
  };

  config = lib.mkIf config.components.application.communication.discord.enable {
    home.packages = with pkgs; [
      discord
    ];

  };
}

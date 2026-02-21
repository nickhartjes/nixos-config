{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.gaming.steam = {
    enable = lib.mkEnableOption "Steam gaming platform";
  };

  config = lib.mkIf config.components.application.gaming.steam.enable {
    home.packages = with pkgs; [
      steam
      steam-run
      steamguard-cli
      steamtinkerlaunch
    ];

  };
}

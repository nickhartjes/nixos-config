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

    # Add telegram-desktop to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "telegram-desktop"
      ];
  };
}

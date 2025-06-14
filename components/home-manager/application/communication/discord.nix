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

    # Add discord to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "discord"
      ];
  };
}

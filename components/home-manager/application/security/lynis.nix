{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.security.lynis = {
    enable = lib.mkEnableOption "Lynis security auditing tool";
  };

  config = lib.mkIf config.components.application.security.lynis.enable {
    home.packages = with pkgs; [
      lynis
    ];

    # Lynis is free software, no need for allowUnfreePredicate
  };
}

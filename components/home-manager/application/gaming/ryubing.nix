{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.gaming.ryubing = {
    enable = lib.mkEnableOption "Ryubing gaming emulator";
  };

  config = lib.mkIf config.components.application.gaming.ryubing.enable {
    home.packages = with pkgs; [
      ryubing
    ];
  };
}

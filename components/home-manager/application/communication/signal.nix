{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.communication.signal = {
    enable = lib.mkEnableOption "Signal private messenger";
  };

  config = lib.mkIf config.components.application.communication.signal.enable {
    home.packages = with pkgs; [
      signal-desktop
    ];

  };
}

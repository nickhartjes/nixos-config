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

    # Add signal-desktop to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "signal-desktop"
      ];
  };
}

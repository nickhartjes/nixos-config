{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.security.protonvpn = {
    enable = lib.mkEnableOption "ProtonVPN GUI and CLI tools";
  };

  config = lib.mkIf config.components.application.security.protonvpn.enable {
    home.packages = with pkgs; [
      protonvpn-gui
    ];

  };
}

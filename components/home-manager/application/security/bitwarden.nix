{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.security.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden password manager (CLI and GUI)";
  };

  config = lib.mkIf config.components.application.security.bitwarden.enable {
    home.packages = with pkgs; [
      bitwarden-cli
      bitwarden-desktop
    ];
  };
}

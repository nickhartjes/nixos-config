{
  config,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  options.components.features.desktop.dms = {
    enable = lib.mkEnableOption "Dank Material Shell configuration";
  };

  config = lib.mkIf config.components.features.desktop.dms.enable {
    programs.dank-material-shell = {
      enable = true;
      systemd.enable = false;
      enableSystemMonitoring = false; # dgop package not available in nixos-25.11
    };
  };
}

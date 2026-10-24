{
  config,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  options.components.features.desktop.caelestia = {
    enable = lib.mkEnableOption "Caelestia shell configuration";
  };

  config = lib.mkIf config.components.features.desktop.caelestia.enable {
    programs.caelestia = {
      enable = true;
      # Started by the compositor (exec_once), like DMS and Noctalia.
      systemd.enable = false;
    };
  };
}

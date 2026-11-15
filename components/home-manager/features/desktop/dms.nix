{
  config,
  lib,
  pkgs,
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
      # The compositor module turns this on and picks the target (mangowc.nix).
      systemd.enable = lib.mkDefault false;
      enableSystemMonitoring = true;
    };

    # DMS looks for these on PATH and the module installs neither: `dgop` for
    # the system-monitor widgets and process list, `amdgpu_top` for the GPU
    # widget (otherwise it fails to spawn it every 4 s and floods the log).
    home.packages = [
      inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.amdgpu_top
    ];
  };
}

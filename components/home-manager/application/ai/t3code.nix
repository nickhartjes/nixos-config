{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.components.application.ai.t3code;
in {
  options.components.application.ai.t3code = {
    enable = lib.mkEnableOption "T3 Code for coding agents";
    server.enable = lib.mkEnableOption "persistent T3 Code server";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.t3code];

    systemd.user.services.t3code = lib.mkIf cfg.server.enable {
      Unit.Description = "T3 Code server";
      Install.WantedBy = ["default.target"];
      Service = {
        ExecStart = "${pkgs.t3code}/bin/t3 serve";
        WorkingDirectory = "%h";
        Environment = [
          "T3CODE_HOST=127.0.0.1"
          "T3CODE_PORT=3773"
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
    };
  };
}

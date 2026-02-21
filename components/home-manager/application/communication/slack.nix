{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.communication.slack = {
    enable = lib.mkEnableOption "Slack communication platform";
  };

  config = lib.mkIf config.components.application.communication.slack.enable {
    home.packages = with pkgs; [
      slack
    ];

  };
}

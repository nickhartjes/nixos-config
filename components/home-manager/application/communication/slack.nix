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

    # Add slack to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "slack"
      ];
  };
}

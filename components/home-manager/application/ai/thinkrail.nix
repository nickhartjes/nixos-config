{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.ai.thinkrail = {
    enable = lib.mkEnableOption "ThinkRail agentic IDE (pi coding agent)";
  };

  config = lib.mkIf config.components.application.ai.thinkrail.enable {
    home.packages = [
      (pkgs.callPackage ../../../../pkgs/thinkrail {})
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.ai.opencode = {
    enable = lib.mkEnableOption "OpenCode local AI models";
  };

  config = lib.mkIf config.components.application.ai.opencode.enable {
    home.packages = with pkgs; [
      opencode
    ];
  };
}

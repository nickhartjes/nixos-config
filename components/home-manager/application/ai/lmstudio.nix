{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.ai.lmstudio = {
    enable = lib.mkEnableOption "LMStudio local AI models";
  };

  config = lib.mkIf config.components.application.ai.lmstudio.enable {
    home.packages = with pkgs; [
      lmstudio
    ];
  };
}

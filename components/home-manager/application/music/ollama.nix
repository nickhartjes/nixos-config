{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.music.ollama = {
    enable = lib.mkEnableOption "Ollama local AI models";
  };

  config = lib.mkIf config.components.application.music.ollama.enable {
    home.packages = with pkgs; [
      ollama
    ];

    # Ollama is free software, no need for allowUnfreePredicate
  };
}

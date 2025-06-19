{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.ai.alpaca = {
    enable = lib.mkEnableOption "Alpaca - Ollama client made with GTK4 and Adwaita";
  };

  config = lib.mkIf config.components.application.ai.alpaca.enable {
    home.packages = with pkgs; [
      alpaca
    ];
  };
}

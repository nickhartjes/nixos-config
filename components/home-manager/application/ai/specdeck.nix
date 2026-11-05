{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.components.application.ai.specdeck = {
    enable = lib.mkEnableOption "SpecDeck (run a coding agent with your team watching along)";
  };

  config = lib.mkIf config.components.application.ai.specdeck.enable {
    # Built from source by the specdeck flake input. Without an override the
    # build bakes in the local dev stack (ws://127.0.0.1:18081/signal), so
    # point it at the signalling service on hetzner-specdeck.
    home.packages = [
      (inputs.specdeck.packages.${pkgs.stdenv.hostPlatform.system}.specdeck.override {
        signallingUrl = "wss://specdeck.hartj.es/signal";
      })
    ];
  };
}

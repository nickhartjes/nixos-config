{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in {
  options.components.application.ai.codex = {
    enable = lib.mkEnableOption "OpenAI Codex CLI";
  };

  config = lib.mkIf config.components.application.ai.codex.enable {
    programs.codex = {
      enable = true;
      package = pkgs-unstable.codex;
    };
  };
}

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
  options.components.application.ai.antigravity = {
    enable = lib.mkEnableOption "Google Antigravity IDE and its CLI (agy)";
  };

  config = lib.mkIf config.components.application.ai.antigravity.enable {
    home.packages = [
      # FHS variant so VS Code-style extensions with prebuilt binaries work
      # without nix-specific patching.
      pkgs-unstable.antigravity-ide-fhs
      pkgs-unstable.antigravity-cli # provides `agy`
    ];
  };
}

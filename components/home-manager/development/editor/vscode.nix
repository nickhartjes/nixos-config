{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.development.editor.vscode;
in {
  options.components.development.editor.vscode.enable = mkEnableOption "enable fuzzy finder";

  # Find more options at:
  # https://home-manager-options.extranix.com/?query=vscode

  config = mkIf cfg.enable {
    programs = {
      vscode = {
        enable = true;
        package = pkgs.vscodium;
        profiles.default.extensions = with pkgs; [
          vscode-extensions.redhat.java
        ];
      };
    };
  };
}

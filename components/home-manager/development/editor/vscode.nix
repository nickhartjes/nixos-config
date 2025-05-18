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
        package = pkgs.vscode;
        profiles.default.extensions = with pkgs; [
          vscode-extensions.redhat.java
          vscode-extensions.jnoortheen.nix-ide
          vscode-extensions.nefrob.vscode-just-syntax

          vscode-extensions.catppuccin.catppuccin-vsc
          vscode-extensions.catppuccin.catppuccin-vsc-icons
        ];
      };
    };

    # Application needed for the vscode configuration to work properly
    home.packages = with pkgs; [
      nixfmt-rfc-style
    ];
  };
}

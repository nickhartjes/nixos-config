{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in {
  options.components.application.ai.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI assistant";
  };

  config = lib.mkIf config.components.application.ai.claude-code.enable {
    home.packages = [
      pkgs-unstable.claude-code
    ];

    # Add claude-code to allowUnfreePredicate if not globally allowed
    # nixpkgs.config = {
    #   allowUnfree = true;
    #   allowUnfreePredicate = pkg:
    #     builtins.elem (lib.getName pkg) [
    #       "claude-code"
    #       "vscode-extension-anthropic-claude-code"
    #     ];
    # };
  };
}

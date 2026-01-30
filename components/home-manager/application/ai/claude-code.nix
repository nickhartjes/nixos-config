{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.ai.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI assistant";
  };

  config = lib.mkIf config.components.application.ai.claude-code.enable {
    home.packages = with pkgs; [
      claude-code
    ];

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "claude-code"
        # "vscode-extension-anthropic-claude-code"
        # "vcode-extensions.anthropic.claude-code"
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

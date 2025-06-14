{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.music.claude-desktop = {
    enable = lib.mkEnableOption "Claude Desktop AI assistant";
  };

  config = lib.mkIf config.components.application.music.claude-desktop.enable {
    home.packages = with pkgs; [
      claude-desktop
    ];

    # Add claude-desktop to allowUnfreePredicate if not globally allowed
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "claude-desktop"
      ];
  };
}

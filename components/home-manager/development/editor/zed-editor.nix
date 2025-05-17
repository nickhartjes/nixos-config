{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.development.editor.zed;
in {
  options.components.development.editor.zed.enable = mkEnableOption "enable fuzzy finder";

  # Find more options at:
  # https://home-manager-options.extranix.com/?query=zed-editor

  config = mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      # https://github.com/zed-industries/extensions/tree/main/extensions
      extensions = ["nix"];
    };
  };
}

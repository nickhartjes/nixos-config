{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.development.editor.intellij;
in {
  options.components.development.editor.intellij.enable = mkEnableOption "enable IntelliJ IDEA";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      jetbrains.idea-ultimate
    ];

    home.file.".ideavimrc".text = ''
      " Enable IdeaVim plugin settings
      set clipboard+=unnamed
      set ignorecase
      set smartcase
      set incsearch
      set hlsearch
    '';
  };
}

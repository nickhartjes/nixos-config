{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.neovim;
in {
  options.components.cli.neovim.enable = mkEnableOption "enable neovim";

  config = mkIf cfg.enable {
    programs.neovim = {
      vimAlias = true;
      enable = true;
      # plugins = with pkgs.vimPlugins; [
      #   LazyVim
      #   nvchad
      #   nvchad-ui
      #   vim-nix
      # ];
    };
    home.packages = with pkgs; [
      ripgrep # For use with Telescope
    ];
  };
}

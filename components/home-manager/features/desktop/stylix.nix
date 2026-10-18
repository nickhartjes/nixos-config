{
  config,
  lib,
  options,
  ...
}: let
  cfg = config.components.features.desktop.stylix;
  noFonts = {fonts.enable = false;};
  noFontsOpacity = {
    fonts.enable = false;
    opacity.enable = false;
  };
in {
  options.components.features.desktop.stylix = {
    enable = lib.mkEnableOption "Stylix color theming for user applications (colors only)";
  };

  # `stylix` HM options only exist on hosts that import the Stylix NixOS module
  # (framework-13); guard the definitions so the other hosts still evaluate.
  config = lib.optionalAttrs (options ? stylix) {
    stylix.targets = lib.mkIf cfg.enable {
      # Colors only: fonts and opacity stay as configured per app.
      ghostty = noFontsOpacity // {enable = true;};
      alacritty = noFontsOpacity // {enable = true;};
      # foot's color block is skipped entirely when its opacity option is
      # disabled; opacity.terminal is 1.0 (foot's own default), so keep it on.
      foot = noFonts // {enable = true;};
      kitty = noFontsOpacity // {enable = true;};
      wezterm = noFontsOpacity // {enable = true;};
      btop = {
        enable = true;
        opacity.enable = false;
      };
      vscode = noFonts // {enable = true;};
      gtk = noFonts // {enable = true;};
      neovim.enable = true;
      k9s.enable = true;
      lazygit.enable = true;

      # Excluded areas keep their own theming.
      kde.enable = false;
      qt.enable = false;
      dank-material-shell.enable = false;
      dank-calendar.enable = false;
      noctalia.enable = false;
      noctalia-shell.enable = false;
      font-packages.enable = false;
      fontconfig.enable = false;
    };
  };
}

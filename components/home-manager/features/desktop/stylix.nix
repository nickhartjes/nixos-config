{
  config,
  lib,
  options,
  osConfig ? null,
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
  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.enable || (osConfig != null && osConfig ? stylix && osConfig.stylix.enable);
          message = "components.features.desktop.stylix.enable requires Stylix on the host (components.system.stylix.enable = true and the stylix NixOS module imported).";
        }
      ];
    }
    (lib.optionalAttrs (options ? stylix) {
      stylix.targets = lib.mkIf cfg.enable {
        # Colors only: fonts and opacity stay as configured per app.
        ghostty = noFontsOpacity // {enable = true;};
        alacritty = noFontsOpacity // {enable = true;};
        # foot's color block is skipped entirely when its opacity option is
        # disabled; opacity.terminal is 1.0 (foot's own default), so keep it on.
        foot = noFonts // {enable = true;};
        kitty = noFontsOpacity // {enable = true;};
        wezterm = noFontsOpacity // {enable = true;};
        # Skipped: btop is not HM-managed and rewrites its own btop.conf;
        # enabling programs.btop would fight it.
        btop.enable = false;
        vscode = noFonts // {enable = true;};
        # Skipped: Plasma/DMS/nwg-look own and rewrite the GTK files, and the
        # target would change font/icon/cursor settings, not just colors.
        gtk.enable = false;
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
    })

    (lib.mkIf cfg.enable (
      let
        c = config.lib.stylix.colors or null;
      in
        lib.optionalAttrs (options ? stylix) {
          # lazygit's config.yml is an empty unmanaged file on existing hosts;
          # let the Stylix-managed one replace it.
          home.file."${config.xdg.configHome}/lazygit/config.yml".force = true;
        }
        // lib.optionalAttrs (options ? stylix) {
          wayland.windowManager.mango.settings = lib.mkIf (c != null) {
            focus_color = lib.mkForce "0x${c.base0D}ff";
            border_color = lib.mkForce "0x${c.base02}ff";
            scratchpad_color = lib.mkForce "0x${c.base0C}ff";
          };
        }
        // lib.optionalAttrs (options ? programs.niri) {
          programs.niri.settings.layout.focus-ring = lib.mkIf (c != null) {
            active.color = lib.mkForce "#${c.base0D}";
            inactive.color = lib.mkForce "#${c.base02}";
          };
        }
    ))
  ];
}

# Desktop, terminal, and CLI configuration for user nh
{
  components = {
    cli = {
      bat.enable = false;
      fastfetch.enable = true;
      fish.enable = true;
      fzf.enable = true;
      neofetch.enable = true;
      neovim.enable = true;
      nh.enable = true;
      nvtop.enable = true;
      ssh.enable = true;
      zsh.enable = true;
    };
    terminal = {
      alacritty.enable = true;
      foot.enable = true;
      ghostty.enable = true;
      kitty.enable = true;
      wezterm.enable = true;
    };
    features = {
      desktop = {
        hyprland.enable = true;
        mangowc.enable = true;
        mangowc.enableNoctalia = true;
        mangowc.enableDMS = false;
        dms.enable = false;
        niri.enable = true;
        niri.enableNoctalia = true;
        noctalia.enable = true;
        sway.enable = false;
      };
    };
    desktop = {
      fonts.enable = true;
      wayland.enable = false;
    };
  };

  # KDE Plasma configuration using plasma-manager
  programs.plasma = {
    enable = true;

    # Basic workspace configuration
    workspace = {
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";
    };

    # Simple shortcuts
    shortcuts = {
      "kwin"."Switch to Desktop 1" = "Meta+1";
      "kwin"."Switch to Desktop 2" = "Meta+2";
      "kwin"."Switch to Desktop 3" = "Meta+3";
      "kwin"."Switch to Desktop 4" = "Meta+4";
      "kwin"."Window Close" = "Meta+Q,Alt+F4,Close Window";
      "org.freedesktop.krunner.desktop"."_launch" = "Meta";
      "services/org.freedesktop.krunner.desktop"."_launch" = "Meta";
      "services/com.mitchellh.ghostty.desktop"."new-window" = "Meta+Return";
    };

    # Basic configuration files
    configFile = {
      "kdeglobals"."General"."BrowserApplication" = "chromium-browser.desktop";
      "kdeglobals"."General"."TerminalApplication" = "com.github.ghostty";
      "kdeglobals"."General"."TerminalService" = "com.github.ghostty";
      "kwinrc"."Desktops"."Id_1" = "Desktop_1";
      "kwinrc"."Desktops"."Id_2" = "Desktop_2";
      "kwinrc"."Desktops"."Id_3" = "Desktop_3";
      "kwinrc"."Desktops"."Id_4" = "Desktop_4";
      "kwinrc"."Desktops"."Name_1" = "Main";
      "kwinrc"."Desktops"."Name_2" = "Work";
      "kwinrc"."Desktops"."Name_3" = "Media";
      "kwinrc"."Desktops"."Name_4" = "Dev";
      "kwinrc"."Desktops"."Number" = 4;
      "kwinrc"."Desktops"."Rows" = 1;
    };
  };
}

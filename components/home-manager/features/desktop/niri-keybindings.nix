# Niri keybindings — imported by niri.nix
{
  pkgs,
  noctalia,
  enableNoctalia,
  lib,
}: let
  terminal = "${pkgs.ghostty}/bin/ghostty";
in
  {
    # Application launchers
    "Mod+Return".action.spawn = [terminal];
    "Mod+Return".hotkey-overlay.title = "Open terminal";
    "Mod+D".action.spawn = ["${pkgs.wofi}/bin/wofi" "--show" "drun"];
    "Mod+D".hotkey-overlay.title = "App launcher (wofi)";
    "Mod+B".action.spawn = ["chromium"];
    "Mod+B".hotkey-overlay.title = "Open browser";

    # Keybinding cheat sheet
    "Mod+Shift+Slash".action.show-hotkey-overlay = [];

    # Window management
    "Mod+Q".action.close-window = [];
    "Mod+Shift+E".action.quit = [];

    # Focus movement
    "Mod+H".action.focus-column-left = [];
    "Mod+J".action.focus-window-down = [];
    "Mod+K".action.focus-window-up = [];
    "Mod+L".action.focus-column-right = [];
    "Mod+Left".action.focus-column-left = [];
    "Mod+Down".action.focus-window-down = [];
    "Mod+Up".action.focus-window-up = [];
    "Mod+Right".action.focus-column-right = [];

    # Move windows
    "Mod+Shift+H".action.move-column-left = [];
    "Mod+Shift+J".action.move-window-down = [];
    "Mod+Shift+K".action.move-window-up = [];
    "Mod+Shift+L".action.move-column-right = [];
    "Mod+Shift+Left".action.move-column-left = [];
    "Mod+Shift+Down".action.move-window-down = [];
    "Mod+Shift+Up".action.move-window-up = [];
    "Mod+Shift+Right".action.move-column-right = [];

    # Workspace navigation
    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;

    # Move window to workspace
    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;

    # Column width adjustments
    "Mod+R".action.switch-preset-column-width = [];
    "Mod+F".action.maximize-column = [];
    "Mod+Shift+F".action.fullscreen-window = [];

    # Column sizing
    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Equal".action.set-column-width = "+10%";

    # Scrolling (niri's unique feature)
    "Mod+WheelScrollDown".action.focus-workspace-down = [];
    "Mod+WheelScrollUp".action.focus-workspace-up = [];
    "Mod+Shift+WheelScrollDown".action.move-column-to-workspace-down = [];
    "Mod+Shift+WheelScrollUp".action.move-column-to-workspace-up = [];

    # Screenshots
    "Print".action.screenshot = [];
    "Shift+Print".action.screenshot-window = [];
    "Ctrl+Print".action.screenshot-screen = [];

    # Consume/expel windows from columns
    "Mod+Comma".action.consume-window-into-column = [];
    "Mod+Period".action.expel-window-from-column = [];
  }
  # Noctalia keybindings (when enabled)
  // lib.optionalAttrs enableNoctalia {
    "Mod+Space".action.spawn = noctalia "panel-toggle launcher";
    "Mod+Space".hotkey-overlay.title = "Launcher";
    "Mod+P".action.spawn = noctalia "panel-toggle session";
    "Mod+P".hotkey-overlay.title = "Session menu";
    "Mod+O".action.toggle-overview = [];
    "Mod+O".hotkey-overlay.title = "Overview";
    "Mod+Ctrl+L".action.spawn = noctalia "session lock";
    "Mod+Ctrl+L".hotkey-overlay.title = "Lock screen";
    "Mod+V".action.spawn = noctalia "panel-toggle clipboard";
    "Mod+V".hotkey-overlay.title = "Clipboard history";
    "Mod+E".action.spawn = noctalia "panel-toggle launcher /emo";
    "Mod+E".hotkey-overlay.title = "Emoji picker";
    "Mod+Tab".action.spawn = noctalia "window-switcher hold";
    "Mod+Tab".hotkey-overlay.title = "Window switcher";
    "Mod+N".action.spawn = noctalia "panel-toggle control-center";
    "Mod+N".hotkey-overlay.title = "Control center";
    "XF86AudioRaiseVolume".action.spawn = noctalia "volume-up";
    "XF86AudioLowerVolume".action.spawn = noctalia "volume-down";
    "XF86AudioMute".action.spawn = noctalia "volume-mute";
    "XF86MonBrightnessUp".action.spawn = noctalia "brightness-up";
    "XF86MonBrightnessDown".action.spawn = noctalia "brightness-down";
  }

# MangoWC keybindings — imported by mangowc.nix
{
  pkgs,
  noctalia,
  dms,
  hasShell,
  enableNoctalia,
  enableDMS,
  lib,
}: let
  # A bind with a description. DMS's keybind viewer shows the `# comment`
  # above a bind; without one, spawn binds show their raw /nix/store command.
  d = desc: bind: {inherit desc bind;};
  noctaliaBinds = lib.optionals enableNoctalia [
    (d "Launcher" "SUPER,SPACE,spawn,${noctalia "launcher toggle"}")
    (d "Session menu" "SUPER,P,spawn,${noctalia "sessionMenu toggle"}")
    (d "Overview" "SUPER,O,spawn,${noctalia "overview toggle"}")
    (d "Lock screen" "CTRL+SUPER,L,spawn,${noctalia "lockScreen lock"}")
    (d "Clipboard history" "SUPER,V,spawn,${noctalia "launcher clipboard"}")
    (d "Emoji picker" "SUPER,E,spawn,${noctalia "launcher emoji"}")
    (d "Window switcher" "SUPER,TAB,spawn,${noctalia "launcher windows"}")
    (d "Control center" "SUPER,N,spawn,${noctalia "controlCenter toggle"}")
    (d "Calendar" "SUPER,C,spawn,${noctalia "calendar toggle"}")
    (d "System monitor" "SUPER+SHIFT,ESCAPE,spawn,${noctalia "systemMonitor toggle"}")
    (d "Command launcher" "SUPER+SHIFT,D,spawn,${noctalia "launcher command"}")
  ];

  noctaliaBindls = lib.optionals enableNoctalia [
    (d "Volume up" "NONE,XF86AudioRaiseVolume,spawn,${noctalia "volume increase"}")
    (d "Volume down" "NONE,XF86AudioLowerVolume,spawn,${noctalia "volume decrease"}")
    (d "Mute" "NONE,XF86AudioMute,spawn,${noctalia "volume muteOutput"}")
    (d "Brightness up" "NONE,XF86MonBrightnessUp,spawn,${noctalia "brightness increase"}")
    (d "Brightness down" "NONE,XF86MonBrightnessDown,spawn,${noctalia "brightness decrease"}")
  ];

  dmsBinds = lib.optionals enableDMS [
    (d "Launcher" "SUPER,SPACE,spawn,${dms "spotlight toggle"}")
    (d "Power menu" "SUPER,P,spawn,${dms "powermenu toggle"}")
    (d "Overview" "SUPER,O,spawn,${dms "hypr toggleOverview"}")
    (d "Lock screen" "CTRL+SUPER,L,spawn,${dms "lock lock"}")
    (d "Clipboard history" "SUPER,V,spawn,${dms "clipboard toggle"}")
    (d "Overview" "SUPER,TAB,spawn,${dms "hypr toggleOverview"}")
    (d "Notifications" "SUPER,N,spawn,${dms "notifications toggle"}")
    (d "Control center" "SUPER,C,spawn,${dms "control-center toggle"}")
    (d "Process list" "SUPER+SHIFT,ESCAPE,spawn,${dms "processlist toggle"}")
    (d "DMS settings" "SUPER+SHIFT,D,spawn,${dms "settings toggle"}")
    # Keybinding cheat sheet (DMS parses mango's config)
    (d "Keybinding cheat sheet" "SUPER+SHIFT,slash,spawn,${dms "keybinds toggle mangowc"}")
  ];

  dmsBindls = lib.optionals enableDMS [
    (d "Volume up" "NONE,XF86AudioRaiseVolume,spawn,${dms "audio increment 3"}")
    (d "Volume down" "NONE,XF86AudioLowerVolume,spawn,${dms "audio decrement 3"}")
    (d "Mute" "NONE,XF86AudioMute,spawn,${dms "audio mute"}")
    (d "Brightness up" "NONE,XF86MonBrightnessUp,spawn,${dms "brightness increment 5"}")
    (d "Brightness down" "NONE,XF86MonBrightnessDown,spawn,${dms "brightness decrement 5"}")
  ];
in {
  bind =
    [
      # Application launchers
      (d "Terminal" "SUPER,RETURN,spawn,${pkgs.ghostty}/bin/ghostty")
      (d "Browser" "SUPER,B,spawn,chromium")

      # Window management
      "SUPER,Q,killclient"
      "SUPER+SHIFT,E,quit"
      "SUPER+SHIFT,R,reload_config"
      "SUPER,T,togglefloating"
      "SUPER,Z,focuslast"
      "SUPER+SHIFT,C,centerwin"
      "SUPER,W,switch_proportion_preset"

      # Focus movement
      "SUPER,H,focusdir,left"
      "SUPER,J,focusdir,down"
      "SUPER,K,focusdir,up"
      "SUPER,L,focusdir,right"
      "SUPER,LEFT,focusdir,left"
      "SUPER,DOWN,focusdir,down"
      "SUPER,UP,focusdir,up"
      "SUPER,RIGHT,focusdir,right"

      # Move windows
      "SUPER+SHIFT,H,movewin,left"
      "SUPER+SHIFT,J,movewin,down"
      "SUPER+SHIFT,K,movewin,up"
      "SUPER+SHIFT,L,movewin,right"

      # Tags (workspaces)
      "SUPER,1,view,1,0"
      "SUPER,2,view,2,0"
      "SUPER,3,view,3,0"
      "SUPER,4,view,4,0"
      "SUPER,5,view,5,0"
      "SUPER,6,view,6,0"
      "SUPER,7,view,7,0"
      "SUPER,8,view,8,0"
      "SUPER,9,view,9,0"

      # Move window to tag
      "SUPER+SHIFT,1,tag,1,0"
      "SUPER+SHIFT,2,tag,2,0"
      "SUPER+SHIFT,3,tag,3,0"
      "SUPER+SHIFT,4,tag,4,0"
      "SUPER+SHIFT,5,tag,5,0"
      "SUPER+SHIFT,6,tag,6,0"
      "SUPER+SHIFT,7,tag,7,0"
      "SUPER+SHIFT,8,tag,8,0"
      "SUPER+SHIFT,9,tag,9,0"

      # Fullscreen
      "SUPER,F,togglefullscreen"
      "SUPER,M,togglemaximizescreen"

      # Gap control
      "SUPER,EQUAL,incgaps,+2"
      "SUPER,MINUS,incgaps,-2"
      "SUPER+SHIFT,G,togglegaps"

      # Layout switching
      "SUPER+SHIFT,SPACE,switch_layout"

      # Scratchpad
      (d "Scratchpad terminal" "SUPER,S,toggle_named_scratchpad,foot-scratchpad,none,${pkgs.foot}/bin/foot --app-id=foot-scratchpad")

      # Screenshots
      (d "Screenshot (region)" ''NONE,PRINT,spawn,${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" ~/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png'')
    ]
    ++ lib.optionals (!hasShell) [
      (d "App launcher (wofi)" "SUPER,D,spawn,${pkgs.wofi}/bin/wofi --show drun")
    ]
    ++ noctaliaBinds
    ++ dmsBinds;

  bindl = noctaliaBindls ++ dmsBindls;

  window_rule = [
    "is_named_scratchpad:1,width:1280,height:800,app_id:foot-scratchpad"
    "force_fake_maximize:1,app_id:chromium"
    "force_fake_maximize:1,app_id:firefox"
  ];

  mousebind = [
    "SUPER,btn_left,moveresize,curmove"
    "SUPER,btn_right,moveresize,curresize"
  ];

  gesturebind = [
    "NONE,left,3,viewtoright"
    "NONE,right,3,viewtoleft"
    "NONE,up,3,toggleoverview"
    "NONE,down,4,togglefullscreen"
  ];
}

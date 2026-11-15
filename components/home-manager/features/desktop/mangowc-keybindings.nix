# MangoWC keybindings — imported by mangowc.nix
{
  pkgs,
  noctalia,
  dms,
  caelestia,
  hasShell,
  enableNoctalia,
  enableDMS,
  enableCaelestia,
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
    (d "Lock screen" "CTRL+SUPER,L,spawn,${dms "lock lock"}")
    (d "Clipboard history" "SUPER,V,spawn,${dms "clipboard toggle"}")
    (d "Notifications" "SUPER,N,spawn,${dms "notifications toggle"}")
    (d "Control center" "SUPER,C,spawn,${dms "control-center toggle"}")
    (d "Process list" "SUPER+SHIFT,ESCAPE,spawn,${dms "processlist toggle"}")
    (d "DMS settings" "SUPER+SHIFT,D,spawn,${dms "settings toggle"}")
    # Keybinding cheat sheet (DMS parses mango's config)
    (d "Keybinding cheat sheet" "SUPER+SHIFT,slash,spawn,${dms "keybinds toggle mangowc"}")
    (d "Dashboard" "SUPER,D,spawn,${dms "dash toggle overview"}")
    (d "Notepad" "SUPER,O,spawn,${dms "notepad toggle"}")
    (d "Color picker" "SUPER+SHIFT,P,spawn,${dms "color-picker toggle"}")
    (d "Night light" "SUPER+SHIFT,N,spawn,${dms "night toggle"}")
    (d "Do not disturb" "CTRL+SUPER,N,spawn,${dms "notifications toggleDoNotDisturb"}")
    (d "Keep awake (idle inhibit)" "SUPER+SHIFT,I,spawn,${dms "inhibit toggle"}")
    (d "Cycle power profile" "SUPER+SHIFT,B,spawn,${dms "powerprofile cycle"}")
  ];

  dmsBindls = lib.optionals enableDMS [
    (d "Volume up" "NONE,XF86AudioRaiseVolume,spawn,${dms "audio increment 3"}")
    (d "Volume down" "NONE,XF86AudioLowerVolume,spawn,${dms "audio decrement 3"}")
    (d "Mute" "NONE,XF86AudioMute,spawn,${dms "audio mute"}")
    (d "Brightness up" "NONE,XF86MonBrightnessUp,spawn,${dms "brightness increment 5"}")
    (d "Brightness down" "NONE,XF86MonBrightnessDown,spawn,${dms "brightness decrement 5"}")
    (d "Mic mute" "NONE,XF86AudioMicMute,spawn,${dms "audio micmute"}")
    (d "Play/pause" "NONE,XF86AudioPlay,spawn,${dms "mpris playPause"}")
    (d "Next track" "NONE,XF86AudioNext,spawn,${dms "mpris next"}")
    (d "Previous track" "NONE,XF86AudioPrev,spawn,${dms "mpris previous"}")
  ];
  # Caelestia's drawer toggles and brightness IPC pick the screen through
  # Hyprland's focused monitor, which doesn't exist under mango. Toggles fall
  # back to the first screen; volume/brightness go straight to the tools and
  # Caelestia's OSD picks up the change.
  caelestiaBinds = lib.optionals enableCaelestia [
    (d "Launcher" "SUPER,SPACE,spawn,${caelestia "drawers toggle launcher"}")
    (d "Session menu" "SUPER,P,spawn,${caelestia "drawers toggle session"}")
    (d "Lock screen" "CTRL+SUPER,L,spawn,${caelestia "lock lock"}")
    (d "Notifications" "SUPER,N,spawn,${caelestia "drawers toggle sidebar"}")
    (d "Dashboard" "SUPER,C,spawn,${caelestia "drawers toggle dashboard"}")
    (d "Utilities" "SUPER+SHIFT,D,spawn,${caelestia "drawers toggle utilities"}")
  ];

  caelestiaBindls = lib.optionals enableCaelestia [
    (d "Volume up" "NONE,XF86AudioRaiseVolume,spawn,${pkgs.wireplumber}/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 3%+")
    (d "Volume down" "NONE,XF86AudioLowerVolume,spawn,${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-")
    (d "Mute" "NONE,XF86AudioMute,spawn,${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
    (d "Brightness up" "NONE,XF86MonBrightnessUp,spawn,${pkgs.brightnessctl}/bin/brightnessctl set 5%+")
    (d "Brightness down" "NONE,XF86MonBrightnessDown,spawn,${pkgs.brightnessctl}/bin/brightnessctl set 5%-")
  ];
in {
  bind =
    [
      # Application launchers
      (d "Terminal" "SUPER,RETURN,spawn,${pkgs.ghostty}/bin/ghostty")
      (d "Browser" "SUPER,B,spawn,chromium")

      # Window management
      (d "Close window" "SUPER,Q,killclient")
      (d "Quit mango" "SUPER+SHIFT,E,quit")
      (d "Reload config" "SUPER+SHIFT,R,reload_config")
      (d "Toggle floating" "SUPER,T,togglefloating")
      (d "Focus last window" "SUPER,Z,focuslast")
      (d "Center window" "SUPER+SHIFT,C,centerwin")
      (d "Cycle column width" "SUPER,W,switch_proportion_preset")

      # Focus movement
      (d "Focus left" "SUPER,H,focusdir,left")
      (d "Focus down" "SUPER,J,focusdir,down")
      (d "Focus up" "SUPER,K,focusdir,up")
      (d "Focus right" "SUPER,L,focusdir,right")
      (d "Focus left" "SUPER,LEFT,focusdir,left")
      (d "Focus down" "SUPER,DOWN,focusdir,down")
      (d "Focus up" "SUPER,UP,focusdir,up")
      (d "Focus right" "SUPER,RIGHT,focusdir,right")

      # Move windows (swap with the neighbour; `movewin` takes pixel x,y and
      # floats the window, so `movewin,left` sends it floating to 0,0)
      (d "Swap window left" "SUPER+SHIFT,H,exchange_client,left")
      (d "Swap window down" "SUPER+SHIFT,J,exchange_client,down")
      (d "Swap window up" "SUPER+SHIFT,K,exchange_client,up")
      (d "Swap window right" "SUPER+SHIFT,L,exchange_client,right")
    ]
    # Tags (workspaces): view, and move the focused window there
    ++ lib.concatMap (i: let
      n = toString i;
    in [
      (d "Go to tag ${n}" "SUPER,${n},view,${n},0")
      (d "Move window to tag ${n}" "SUPER+SHIFT,${n},tag,${n},0")
    ]) (lib.range 1 9)
    ++ [
      # Fullscreen
      (d "Fullscreen" "SUPER,F,togglefullscreen")
      (d "Maximize" "SUPER,M,togglemaximizescreen")

      # Gap control
      (d "Grow gaps" "SUPER,EQUAL,incgaps,+2")
      (d "Shrink gaps" "SUPER,MINUS,incgaps,-2")
      (d "Toggle gaps" "SUPER+SHIFT,G,togglegaps")

      # Layout switching
      (d "Next layout" "SUPER+SHIFT,SPACE,switch_layout")

      # Scratchpad
      (d "Scratchpad terminal" "SUPER,S,toggle_named_scratchpad,foot-scratchpad,none,${pkgs.foot}/bin/foot --app-id=foot-scratchpad")

      # Screenshots
      (d "Screenshot (region)" ''NONE,PRINT,spawn,${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" ~/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png'')
    ]
    # mango's own overview; DMS's overview IPC only works under Hyprland.
    # Noctalia has its own overview and uses SUPER+TAB as a window switcher.
    ++ lib.optionals (!enableNoctalia) [
      (d "Overview" "SUPER,TAB,toggleoverview")
    ]
    ++ lib.optionals (!hasShell) [
      (d "App launcher (wofi)" "SUPER,D,spawn,${pkgs.wofi}/bin/wofi --show drun")
    ]
    ++ noctaliaBinds
    ++ dmsBinds
    ++ caelestiaBinds;

  bindl = noctaliaBindls ++ dmsBindls ++ caelestiaBindls;

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

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
  noctaliaBinds = lib.optionals enableNoctalia [
    "SUPER,SPACE,spawn,${noctalia "launcher toggle"}"
    "SUPER,P,spawn,${noctalia "sessionMenu toggle"}"
    "SUPER,O,spawn,${noctalia "overview toggle"}"
    "CTRL+SUPER,L,spawn,${noctalia "lockScreen lock"}"
    "SUPER,V,spawn,${noctalia "launcher clipboard"}"
    "SUPER,E,spawn,${noctalia "launcher emoji"}"
    "SUPER,TAB,spawn,${noctalia "launcher windows"}"
    "SUPER,N,spawn,${noctalia "controlCenter toggle"}"
    "SUPER,C,spawn,${noctalia "calendar toggle"}"
    "SUPER+SHIFT,ESCAPE,spawn,${noctalia "systemMonitor toggle"}"
    "SUPER+SHIFT,D,spawn,${noctalia "launcher command"}"
  ];

  noctaliaBindls = lib.optionals enableNoctalia [
    "NONE,XF86AudioRaiseVolume,spawn,${noctalia "volume increase"}"
    "NONE,XF86AudioLowerVolume,spawn,${noctalia "volume decrease"}"
    "NONE,XF86AudioMute,spawn,${noctalia "volume muteOutput"}"
    "NONE,XF86MonBrightnessUp,spawn,${noctalia "brightness increase"}"
    "NONE,XF86MonBrightnessDown,spawn,${noctalia "brightness decrease"}"
  ];

  dmsBinds = lib.optionals enableDMS [
    "SUPER,SPACE,spawn,${dms "spotlight toggle"}"
    "SUPER,P,spawn,${dms "powermenu toggle"}"
    "SUPER,O,spawn,${dms "hypr toggleOverview"}"
    "CTRL+SUPER,L,spawn,${dms "lock lock"}"
    "SUPER,V,spawn,${dms "clipboard toggle"}"
    "SUPER,TAB,spawn,${dms "hypr toggleOverview"}"
    "SUPER,N,spawn,${dms "notifications toggle"}"
    "SUPER,C,spawn,${dms "control-center toggle"}"
    "SUPER+SHIFT,ESCAPE,spawn,${dms "processlist toggle"}"
    "SUPER+SHIFT,D,spawn,${dms "settings toggle"}"
  ];

  dmsBindls = lib.optionals enableDMS [
    "NONE,XF86AudioRaiseVolume,spawn,${dms "audio increment 3"}"
    "NONE,XF86AudioLowerVolume,spawn,${dms "audio decrement 3"}"
    "NONE,XF86AudioMute,spawn,${dms "audio mute"}"
    "NONE,XF86MonBrightnessUp,spawn,${dms "brightness increment 5"}"
    "NONE,XF86MonBrightnessDown,spawn,${dms "brightness decrement 5"}"
  ];
in {
  bind =
    [
      # Application launchers
      "SUPER,RETURN,spawn,${pkgs.ghostty}/bin/ghostty"
      "SUPER,B,spawn,chromium"

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
      "SUPER,S,toggle_named_scratchpad,foot-scratchpad,none,${pkgs.foot}/bin/foot --app-id=foot-scratchpad"

      # Screenshots
      ''NONE,PRINT,spawn,${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" ~/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png''
    ]
    ++ lib.optionals (!hasShell) [
      "SUPER,D,spawn,${pkgs.wofi}/bin/wofi --show drun"
    ]
    ++ noctaliaBinds
    ++ dmsBinds;

  bindl = noctaliaBindls ++ dmsBindls;

  windowrule = [
    "isnamedscratchpad:1,width:1280,height:800,appid:foot-scratchpad"
    "force_fakemaximize:1,appid:chromium"
    "force_fakemaximize:1,appid:firefox"
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

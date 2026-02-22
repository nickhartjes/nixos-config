# MangoWC keybindings — imported by mangowc.nix
{
  pkgs,
  noctalia,
  hasShell,
  enableNoctalia,
  lib,
}: let
  noctaliaBindings = lib.optionalString enableNoctalia ''
    # Noctalia keybindings
    bind=SUPER,SPACE,spawn,${noctalia "launcher toggle"}
    bind=SUPER,P,spawn,${noctalia "sessionMenu toggle"}
    bind=SUPER,O,spawn,${noctalia "overview toggle"}
    bind=CTRL+SUPER,L,spawn,${noctalia "lockScreen lock"}
    bind=SUPER,V,spawn,${noctalia "launcher clipboard"}
    bind=SUPER,E,spawn,${noctalia "launcher emoji"}
    bind=SUPER,TAB,spawn,${noctalia "launcher windows"}
    bind=SUPER,N,spawn,${noctalia "controlCenter toggle"}
    bind=SUPER,C,spawn,${noctalia "calendar toggle"}
    bind=SUPER+SHIFT,ESCAPE,spawn,${noctalia "systemMonitor toggle"}
    bind=SUPER+SHIFT,D,spawn,${noctalia "launcher command"}
    bindl=NONE,XF86AudioRaiseVolume,spawn,${noctalia "volume increase"}
    bindl=NONE,XF86AudioLowerVolume,spawn,${noctalia "volume decrease"}
    bindl=NONE,XF86AudioMute,spawn,${noctalia "volume muteOutput"}
    bindl=NONE,XF86MonBrightnessUp,spawn,${noctalia "brightness increase"}
    bindl=NONE,XF86MonBrightnessDown,spawn,${noctalia "brightness decrease"}
  '';
in ''
  # Application launchers
  bind=SUPER,RETURN,spawn,${pkgs.ghostty}/bin/ghostty
  ${lib.optionalString (!hasShell) ''
    bind=SUPER,D,spawn,${pkgs.wofi}/bin/wofi --show drun
  ''}
  bind=SUPER,B,spawn,chromium

  # Window management
  bind=SUPER,Q,killclient
  bind=SUPER+SHIFT,E,quit
  bind=SUPER+SHIFT,R,reload_config
  bind=SUPER,T,togglefloating
  bind=SUPER,Z,focuslast
  bind=SUPER+SHIFT,C,centerwin
  bind=SUPER,W,switch_proportion_preset

  # Focus movement
  bind=SUPER,H,focusdir,left
  bind=SUPER,J,focusdir,down
  bind=SUPER,K,focusdir,up
  bind=SUPER,L,focusdir,right
  bind=SUPER,LEFT,focusdir,left
  bind=SUPER,DOWN,focusdir,down
  bind=SUPER,UP,focusdir,up
  bind=SUPER,RIGHT,focusdir,right

  # Move windows
  bind=SUPER+SHIFT,H,movewin,left
  bind=SUPER+SHIFT,J,movewin,down
  bind=SUPER+SHIFT,K,movewin,up
  bind=SUPER+SHIFT,L,movewin,right

  # Tags (workspaces)
  bind=SUPER,1,view,1,0
  bind=SUPER,2,view,2,0
  bind=SUPER,3,view,3,0
  bind=SUPER,4,view,4,0
  bind=SUPER,5,view,5,0
  bind=SUPER,6,view,6,0
  bind=SUPER,7,view,7,0
  bind=SUPER,8,view,8,0
  bind=SUPER,9,view,9,0

  # Move window to tag
  bind=SUPER+SHIFT,1,tag,1,0
  bind=SUPER+SHIFT,2,tag,2,0
  bind=SUPER+SHIFT,3,tag,3,0
  bind=SUPER+SHIFT,4,tag,4,0
  bind=SUPER+SHIFT,5,tag,5,0
  bind=SUPER+SHIFT,6,tag,6,0
  bind=SUPER+SHIFT,7,tag,7,0
  bind=SUPER+SHIFT,8,tag,8,0
  bind=SUPER+SHIFT,9,tag,9,0

  # Fullscreen
  bind=SUPER,F,togglefullscreen
  bind=SUPER,M,togglemaximizescreen

  # Gap control
  bind=SUPER,EQUAL,incgaps,+2
  bind=SUPER,MINUS,incgaps,-2
  bind=SUPER+SHIFT,G,togglegaps

  # Layout switching
  bind=SUPER+SHIFT,SPACE,switch_layout

  # Terminal scratchpad (foot — Ghostty GTK doesn't support custom app_id)
  windowrule=isnamedscratchpad:1,width:1280,height:800,appid:foot-scratchpad
  bind=SUPER,S,toggle_named_scratchpad,foot-scratchpad,none,${pkgs.foot}/bin/foot --app-id=foot-scratchpad

  # Screenshots
  bind=NONE,PRINT,spawn,${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" ~/Pictures/Screenshots/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png

  # Window rules
  windowrule=force_maximize:1,appid:chromium
  windowrule=force_maximize:1,appid:firefox

  # Mouse bindings (Super+drag to move/resize)
  mousebind=SUPER,btn_left,moveresize,curmove
  mousebind=SUPER,btn_right,moveresize,curresize

  # Gesture bindings (trackpad swipes)
  gesturebind=NONE,left,3,viewtoright
  gesturebind=NONE,right,3,viewtoleft
  gesturebind=NONE,up,3,toggleoverview
  gesturebind=NONE,down,4,togglefullscreen

  ${noctaliaBindings}
''

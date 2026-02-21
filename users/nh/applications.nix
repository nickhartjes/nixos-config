# Application component enables for user nh
{
  components.application = {
    browser = {
      chromium.enable = true;
      firefox.enable = true;
    };
    music = {
      spotify.enable = true;
    };
    ai = {
      claude-code.enable = true;
      ollama.enable = true;
      alpaca.enable = true;
      opencode.enable = true;
      lmstudio.enable = true;
    };
    communication = {
      slack.enable = true;
      discord.enable = true;
      signal.enable = true;
      telegram.enable = true;
    };
    graphics = {
      gimp.enable = true;
      inkscape.enable = true;
      flameshot.enable = true;
    };
    "3d" = {
      bambu-studio.enable = true;
      openscad.enable = true;
      freecad.enable = true;
    };
    database = {
      dbeaver.enable = true;
      pgadmin.enable = true;
      pgmodeler.enable = true;
      supabase.enable = true;
    };
    office = {
      libreoffice.enable = true;
      anytype.enable = true;
    };
    media = {
      kdenlive.enable = true;
      mpv.enable = true;
      obs.enable = true;
      vlc.enable = true;
    };
    security = {
      lynis.enable = true;
      protonvpn.enable = true;
    };
    gaming = {
      steam.enable = true;
      lutris.enable = true;
      ryubing.enable = true;
    };
    system = {
      mission-center.enable = true;
    };
  };
}

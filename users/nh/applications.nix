# Application component enables for user nh
{
  components.application = {
    browser = {
      chromium.enable = true;
      firefox.enable = true;
      librewolf.enable = true;
    };
    music = {
      spotify.enable = true;
    };
    ai = {
      claude-code.enable = true;
      ollama.enable = true;
      alpaca.enable = false;
      opencode.enable = true;
      codex.enable = true;
      lmstudio.enable = false;
      orca.enable = true;
      thinkrail.enable = false;
      specdeck.enable = true;
    };
    communication = {
      slack.enable = true;
      discord.enable = true;
      signal.enable = true;
      telegram.enable = true;
    };
    graphics = {
      gimp.enable = false;
      inkscape.enable = false;
      flameshot.enable = false;
    };
    "3d" = {
      bambu-studio.enable = true;
      openscad.enable = false;
      freecad.enable = true;
      solidcraft.enable = true;
    };
    database = {
      dbeaver.enable = false;
      pgadmin.enable = false;
      pgmodeler.enable = false;
      supabase.enable = false;
    };
    office = {
      libreoffice.enable = true;
      anytype.enable = false;
    };
    media = {
      kdenlive.enable = true;
      mpv.enable = true;
      obs.enable = true;
      vlc.enable = true;
    };
    security = {
      bitwarden.enable = true;
      lynis.enable = true;
      openssl.enable = true;
      protonvpn.enable = true;
    };
    gaming = {
      steam.enable = true;
      lutris.enable = false;
      ryubing.enable = false;
    };
    system = {
      mission-center.enable = true;
    };
  };

  # ArtCraft creative suite (flake input `artcraft`); defaults to every app.
  programs.artcraft.enable = true;
}

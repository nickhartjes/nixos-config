{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.communication.signal = {
    enable = lib.mkEnableOption "Signal private messenger";
  };

  config = lib.mkIf config.components.application.communication.signal.enable {
    # The DB key is encrypted with kwallet6; Electron can't autodetect that
    # outside Plasma, and the wrong backend fails with SQLITE_NOTADB.
    # nixpkgs dropped `commandLineArgs`; the desktop entry execs
    # `signal-desktop` via PATH, so wrapping the binary covers it too.
    home.packages = [
      (pkgs.symlinkJoin {
        name = "signal-desktop-kwallet6";
        paths = [pkgs.signal-desktop];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/signal-desktop \
            --add-flags "--password-store=kwallet6"
        '';
      })
    ];
  };
}

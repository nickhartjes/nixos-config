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
    home.packages = [
      (pkgs.signal-desktop.override {
        commandLineArgs = "--password-store=kwallet6";
      })
    ];
  };
}

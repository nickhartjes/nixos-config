{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.application.browser.chromium;
in {
  options.components.application.browser.chromium.enable = mkEnableOption "enable Chromium browser";

  config = mkIf cfg.enable {
    programs.chromium = {
      enable = true;
      extensions = [
        "blipmdconlkpinefehnmjammfjpmpbjk" # Lighthouse
        "bcjindcccaagfpapjjmafapmmgkkhgoa" # JSON Formatter
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "mlomiejdfkolichcflejclcbmpeaniij" # Ghostery
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
        "dbfoemgnkgieejfkaddieamagdfepnff" # 2fas two-factor authenticator
      ];
      commandLineArgs = [
        "--homepage='tweakers.net'"
        "--force-dark-mode"
        "--ozone-platform-hint=auto"
      ];
    };
  };
}

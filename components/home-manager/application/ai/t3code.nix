{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.components.application.ai.t3code;
  nightly = inputs.t3code-flake.packages.${pkgs.stdenv.hostPlatform.system}.t3-code-nightly;
  # Public production configuration from upstream v0.1.8 .env.example.
  t3code =
    pkgs.runCommand "t3code-nightly-${nightly.version}" {
      meta = nightly.meta // {mainProgram = "t3code-desktop";};
      nativeBuildInputs = [pkgs.makeWrapper];
    } ''
      mkdir -p "$out/bin" "$out/share/applications"
      ln -s ${nightly}/share/icons "$out/share/icons"
      sed 's/^Exec=t3code /Exec=t3code-desktop /' \
        ${nightly}/share/applications/t3-code-nightly.desktop > "$out/share/applications/t3-code-nightly.desktop"
      # Both the CLI and the desktop app (whose embedded server owns ~/.t3 when
      # it runs) need the T3 Connect configuration.
      for bin in t3 t3code-desktop; do
        program="$bin"
        if [ "$bin" = t3code-desktop ]; then
          program=t3code
        fi
        makeWrapper "${nightly}/bin/$program" "$out/bin/$bin" \
          --prefix PATH : ${lib.makeBinPath [pkgs.codex pkgs.gh pkgs.git]} \
          --set-default T3CODE_CLOUDFLARED_PATH ${lib.getExe pkgs.cloudflared} \
          --set-default T3CODE_CLERK_PUBLISHABLE_KEY pk_live_Y2xlcmsudDMuY29kZXMk \
          --set-default T3CODE_CLERK_JWT_TEMPLATE t3-relay \
          --set-default T3CODE_CLERK_CLI_OAUTH_CLIENT_ID hzxSgY2cH10sDU2r \
          --set-default T3CODE_RELAY_URL https://relay.t3.codes
      done
      ${lib.optionalString (cfg.passwordStore != null) ''
        wrapProgram "$out/bin/t3code-desktop" \
          --add-flags ${lib.escapeShellArg "--password-store=${cfg.passwordStore}"}
      ''}
    '';
in {
  options.components.application.ai.t3code = {
    enable = lib.mkEnableOption "T3 Code for coding agents";
    server.enable = lib.mkEnableOption "persistent T3 Code server";
    passwordStore = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["kwallet6" "kwallet5" "gnome-libsecret"]);
      default = null;
      description = "Explicit Electron secure storage backend for desktop sessions without autodetection.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [t3code];

    systemd.user.services.t3code = lib.mkIf cfg.server.enable {
      Unit.Description = "T3 Code server";
      Install.WantedBy = ["default.target"];
      Service = {
        ExecStart = "${t3code}/bin/t3 serve";
        WorkingDirectory = "%h";
        Environment = [
          "T3CODE_HOST=127.0.0.1"
          "T3CODE_PORT=3773"
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
        ];
        Restart = "on-failure";
        RestartSec = 5;
        UMask = "0077";
      };
    };
  };
}

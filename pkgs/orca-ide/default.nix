# Orca — agent development environment (https://www.onorca.dev), packaged from
# the upstream Electron AppImage. Upstream releases almost daily; bump version
# and hash with `nix store prefetch-file <AppImage url>`.
{
  appimageTools,
  fetchurl,
}: let
  pname = "orca";
  version = "1.4.239";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-nBC1SLUw4I/BI6RnRqo7+mbhXjSfqQFKdaKt3FxPJs0=";
  };

  contents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${contents}/orca-ide.desktop $out/share/applications/orca.desktop
      # Upstream claims text/markdown and CSV too; keep only its own URL scheme
      # so it doesn't compete for the default markdown/CSV handler.
      substituteInPlace $out/share/applications/orca.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=orca' \
        --replace-fail 'MimeType=text/markdown;text/csv;text/tab-separated-values;x-scheme-handler/orca;' 'MimeType=x-scheme-handler/orca;'
      cp -r ${contents}/usr/share/icons $out/share/
    '';

    meta = {
      description = "Agent development environment for running coding agents in parallel worktrees";
      homepage = "https://www.onorca.dev";
      mainProgram = "orca";
      platforms = ["x86_64-linux"];
    };
  }

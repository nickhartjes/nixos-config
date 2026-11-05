# ThinkRail — JetBrains' agentic IDE around the `pi` coding agent
# (https://thinkrail.ai), packaged from the upstream Electrobun app bundle
# (`stable-linux-x64-ThinkRail-<ver>.tar.zst`) rather than the self-installer,
# which unpacks into ~/.local/share and self-updates. Bump version and hash
# with `nix store prefetch-file <tar.zst url>`.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zstd,
  webkitgtk_4_1,
  libsoup_3,
  glib,
  gtk3,
  cairo,
  gdk-pixbuf,
  libayatana-appindicator,
  git,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "thinkrail";
  version = "0.2.0";

  src = fetchurl {
    url = "https://github.com/JetBrains/thinkrail/releases/download/v${finalAttrs.version}/stable-linux-x64-ThinkRail-${finalAttrs.version}.tar.zst";
    hash = "sha256-QJuN/aI8Cr5ScTG+/3RyMvW3qR3F34tFrTHShD/yjg0=";
  };

  nativeBuildInputs = [autoPatchelfHook makeWrapper zstd];

  buildInputs = [
    stdenv.cc.cc.lib
    webkitgtk_4_1
    libsoup_3
    glib
    gtk3
    cairo
    gdk-pixbuf
    libayatana-appindicator
  ];

  # The bundled bun and its payloads must stay byte-for-byte intact.
  dontStrip = true;

  unpackPhase = ''
    zstd -dc $src | tar x
  '';

  # The launcher finds its libraries next to argv[0], so exec it by its real
  # path through a wrapper instead of symlinking it into bin/.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/thinkrail
    cp -r ThinkRail $out/share/thinkrail/

    makeWrapper $out/share/thinkrail/ThinkRail/bin/launcher $out/bin/thinkrail \
      --prefix PATH : ${lib.makeBinPath [git]}

    install -Dm444 ThinkRail/Resources/appIcon.png $out/share/icons/hicolor/512x512/apps/thinkrail.png
    install -Dm444 ThinkRail/ThinkRail.desktop $out/share/applications/thinkrail.desktop
    substituteInPlace $out/share/applications/thinkrail.desktop \
      --replace-fail 'Exec=launcher' 'Exec=thinkrail' \
      --replace-fail 'Icon=appIcon' 'Icon=thinkrail' \
      --replace-fail 'Categories=Utility;' 'Categories=Development;IDE;'

    runHook postInstall
  '';

  meta = {
    description = "Agentic IDE built around the pi coding agent";
    homepage = "https://thinkrail.ai";
    license = lib.licenses.asl20;
    mainProgram = "thinkrail";
    platforms = ["x86_64-linux"];
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
  };
})

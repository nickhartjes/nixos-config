# Bambu Studio — Bambu Lab's slicer (https://bambulab.com/en/download/studio),
# packaged from the upstream Ubuntu 24.04 AppImage. nixpkgs' source build lags
# upstream and isn't cached, so it compiles locally for a long time. Bump
# version, build stamp and hash with `nix store prefetch-file <AppImage url>`.
{
  appimageTools,
  fetchurl,
}: let
  pname = "bambu-studio";
  version = "02.09.01.70";
  build = "20261103183404";

  src = fetchurl {
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubu24-v${version}-${build}.AppImage";
    hash = "sha256-Zo2rsb5Tx1gYnta8iZNShd6l4K9GIWVGsbr9aILpr/A=";
  };

  contents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    # The login/device pages are WebKitGTK views; glib-networking gives them TLS.
    extraPkgs = pkgs:
      with pkgs; [
        webkitgtk_4_1
        libsoup_3
        glib-networking
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
      ];

    # Without SSL_CERT_FILE it probes Red Hat's /etc/pki path and prompts on
    # every start. Its "English" UI is en_GB, which the host must generate
    # (i18n.extraLocales on framework-13).
    # The session's GIO_EXTRA_MODULES (dconf only) leaks in, and the FHS glib
    # never scans /usr/lib/gio/modules, so the login WebView reports "TLS support
    # is not available" unless glib-networking's module dir is added.
    profile = ''
      export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
      export GIO_EXTRA_MODULES=/usr/lib/gio/modules''${GIO_EXTRA_MODULES:+:$GIO_EXTRA_MODULES}
    '';

    extraInstallCommands = ''
      install -Dm444 ${contents}/BambuStudio.desktop $out/share/applications/bambu-studio.desktop
      substituteInPlace $out/share/applications/bambu-studio.desktop \
        --replace-fail 'Exec=AppRun %U' 'Exec=bambu-studio %U'
      cp -r ${contents}/usr/share/icons $out/share/
    '';

    meta = {
      description = "Bambu Lab's 3D printing slicer";
      homepage = "https://github.com/bambulab/BambuStudio";
      mainProgram = "bambu-studio";
      platforms = ["x86_64-linux"];
    };
  }

{
  stdenv,
  lib,
}:
stdenv.mkDerivation {
  pname = "myfonts";
  version = "1.0";
  src = ./fonts;

  installPhase = ''
    mkdir -p $out/share/fonts/opentype
    cp *.otf $out/share/fonts/opentype/
  '';

  meta = with lib; {
    description = "My custom OTF fonts";
    license = licenses.free;
    platforms = platforms.all;
  };
}

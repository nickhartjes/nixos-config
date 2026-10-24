# SolidCraft — open-source parametric 3D CAD in Rust (https://solidcraft.io),
# packaged from the upstream AppImage. Bump version and hash with
# `nix store prefetch-file <AppImage url>`.
{
  appimageTools,
  fetchurl,
}: let
  pname = "solidcraft";
  version = "0.21.0";

  src = fetchurl {
    url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-${version}-linux-x86_64.AppImage";
    hash = "sha256-LZsqN2Ylk7qJeuzigDzQhlzgaeA0nCx+HDK6Vvw80vI=";
  };

  contents = appimageTools.extract {inherit pname version src;};
in
  appimageTools.wrapType2 {
    inherit pname version src;

    # The desktop file already execs `solidcraft`, the wrapper's binary name.
    extraInstallCommands = ''
      install -Dm444 ${contents}/ai.storyteller.solidcraft.desktop -t $out/share/applications
      cp -r ${contents}/usr/share/icons $out/share/
    '';

    meta = {
      description = "Open-source parametric 3D CAD application";
      homepage = "https://solidcraft.io";
      mainProgram = "solidcraft";
      platforms = ["x86_64-linux"];
    };
  }

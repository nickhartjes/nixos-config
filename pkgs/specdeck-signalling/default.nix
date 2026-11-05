# SpecDeck's signalling service (matchmaking + TURN credentials), without the
# app. Upstream dropped this output from its flake (714d3c5), so it's built here
# from the specdeck flake input's source. Call with `src = inputs.specdeck` and
# `pnpmDeps` from the input's app package (same workspace lockfile, so there is
# no pnpm hash to keep in sync here).
#
# Built with the `web-viewer` feature, as upstream's docker/signalling.Dockerfile
# does: the WebAssembly core (crates/web/pkg), then the page (app/ui/dist-web),
# then the service with the page embedded, served at / and /join.
{
  lib,
  src,
  pnpmDeps,
  rustPlatform,
  buildWasmBindgenCli,
  fetchCrate,
  nodejs,
  pnpm,
  pnpmConfigHook,
  lld,
}: let
  # crates/web pins wasm-bindgen exactly; the CLI must be the same version.
  # A new pin there means new hashes here.
  wasm-bindgen-cli = buildWasmBindgenCli rec {
    src = fetchCrate {
      pname = "wasm-bindgen-cli";
      version = "0.2.130";
      hash = "sha256-9Og1O/6/VC3sc5hBjoIWBErmLW2UHGMsTQO+6+m/dng=";
    };
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      inherit (src) pname version;
      hash = "sha256-j81sUf1m5yXU4FJfGj7GV+hdqVCV8mRmNb0QIsMCjqw=";
    };
  };
in
  rustPlatform.buildRustPackage {
    pname = "specdeck-signalling";
    version = (lib.importTOML (src + "/Cargo.toml")).workspace.package.version;
    inherit src pnpmDeps;

    cargoLock.lockFile = src + "/Cargo.lock";

    nativeBuildInputs = [
      wasm-bindgen-cli
      nodejs
      pnpm
      pnpmConfigHook
      # rustc links wasm32-unknown-unknown with `lld -flavor wasm`.
      lld
    ];

    preBuild = ''
      cargo build --release --frozen -p specdeck-web --target wasm32-unknown-unknown
      wasm-bindgen --target web --out-dir crates/web/pkg \
        target/wasm32-unknown-unknown/release/specdeck_web.wasm
      pnpm --dir app/ui build:web
    '';

    cargoBuildFlags = ["-p" "specdeck-signalling" "--features" "web-viewer"];
    cargoTestFlags = ["-p" "specdeck-signalling" "--features" "web-viewer"];

    meta = {
      description = "SpecDeck matchmaking service and TURN credentials, with the web viewer";
      homepage = "https://github.com/nickhartjes/specdeck";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "specdeck-signalling";
    };
  }

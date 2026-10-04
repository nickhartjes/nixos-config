{
  config,
  lib,
  pkgs,
  ...
}: let
  # TEMP (2026-10-04): psycopg 3.3.5 turned psycopg._encodings._py_codecs from
  # a dict into a tuple of alias groups, and pgadmin's
  # utils/driver/psycopg3/encoding.py mutates that dict at import time, so the
  # app dies with "'tuple' object does not support item assignment" (nixpkgs
  # #569095, Hydra build 347808047). Upstream's own fix is pinning psycopg back
  # to 3.3.4 (pgadmin4 commit 81edb68), not a code change, so the same pin is
  # applied here, scoped to pgadmin's Python only. Drop once pgadmin supports
  # psycopg >= 3.3.5.
  #
  # The version is swapped through fetchFromGitHub and buildPythonPackage
  # because psycopg's expression builds its -c and -pool subpackages from
  # shared let-bindings, which overridePythonAttrs can't reach — and psycopg-c
  # is a build input of psycopg itself, so it has to carry the pin too.
  psycopgVersion = "3.3.4";
  python3 = pkgs.python3.override {
    self = python3;
    packageOverrides = final: prev: {
      psycopg = prev.psycopg.override {
        fetchFromGitHub = args:
          pkgs.fetchFromGitHub (args
            // {
              tag = psycopgVersion;
              hash = "sha256-hHgswbqaoQRQrUxhNFG6tfmlap1mVUo/OkNsWF686U4=";
            });
        buildPythonPackage = args:
          final.buildPythonPackage (args // {version = psycopgVersion;});
      };
    };
  };
in {
  options.components.application.database.pgadmin = {
    enable = lib.mkEnableOption "pgAdmin4 PostgreSQL administration tool";
  };

  config = lib.mkIf config.components.application.database.pgadmin.enable {
    home.packages = [
      (pkgs.pgadmin4-desktopmode.override {inherit python3;})
    ];

    # pgAdmin4 is free software, no need for allowUnfreePredicate
  };
}

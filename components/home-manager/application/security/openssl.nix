{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.security.openssl = {
    enable = lib.mkEnableOption "OpenSSL cryptographic toolkit";
  };

  config = lib.mkIf config.components.application.security.openssl.enable {
    home.packages = with pkgs; [
      openssl
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.languages.rust = {
    enable = lib.mkEnableOption "Rust development environment";
  };

  config = lib.mkIf config.components.development.languages.rust.enable {
    home.packages = with pkgs; [
      rustc
      cargo
      rust-analyzer
    ];
  };
}

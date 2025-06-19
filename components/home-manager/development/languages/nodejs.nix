{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.languages.nodejs = {
    enable = lib.mkEnableOption "Node.js development environment";
  };

  config = lib.mkIf config.components.development.languages.nodejs.enable {
    home.packages = with pkgs; [
      bun
      cypress
      nodejs_22
      nodePackages.npm
      npm-check-updates
      pnpm
      yarn
    ];

    home.file.".npmrc".text = ''
      prefix = ''${HOME}/.npm-packages
    '';
  };
}

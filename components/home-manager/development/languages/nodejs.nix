{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.languages.nodejs = {
    enable = lib.mkEnableOption "Node.js development environment";
    playwright = {
      enable = lib.mkEnableOption "Playwright testing framework";
    };
  };

  config = lib.mkIf config.components.development.languages.nodejs.enable {
    home.packages = with pkgs;
      [
        bun
        cypress
        nodejs_24
        npm-check-updates
        pnpm
        yarn
      ]
      ++ lib.optionals config.components.development.languages.nodejs.playwright.enable [
        playwright-driver.browsers
        playwright-test
      ];

    home.sessionVariables = lib.mkIf config.components.development.languages.nodejs.playwright.enable {
      PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
    };

    home.file.".npmrc".text = ''
      prefix = ''${HOME}/.npm-packages
    '';
  };
}

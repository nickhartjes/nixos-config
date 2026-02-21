{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.display.greetd = {
    enable = lib.mkEnableOption "greetd display manager";
    defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "sway";
      description = "Default session to launch";
    };
  };

  config = lib.mkIf config.components.display.greetd.enable {
    services.greetd.settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${config.components.display.greetd.defaultSession}";
        user = "greeter";
      };
    };
  };
}

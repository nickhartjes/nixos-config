{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.components.cli.fastfetch;
in {
  options.components.cli.fastfetch.enable = mkEnableOption "enable fastfetch";

  config = mkIf cfg.enable {
    programs.fastfetch = {
      enable = true;
      settings = ''
        {
          logo = {
            source = "nixos_small";
            padding = {
              right = 1;
            };
          };
          display = {
            size = {
              binaryPrefix = "si";
            };
            color = "blue";
            separator = "  ";
          };
          modules = [
            {
              type = "datetime";
              key = "Date";
              format = "{1}-{3}-{11}";
            }
            {
              type = "datetime";
              key = "Time";
              format = "{14}:{17}:{20}";
            }
            "break"
            "player"
            "media"
          ];
        };
      '';
    };
  };
}

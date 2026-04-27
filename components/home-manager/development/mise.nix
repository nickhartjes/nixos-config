{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.development.mise;
in {
  options.components.development.mise = {
    enable = mkEnableOption "mise polyglot runtime version manager";

    globalTools = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {
        node = "lts";
        java = "temurin-21";
      };
      description = "Tools and versions to install globally via mise (~/.config/mise/config.toml).";
    };
  };

  config = mkIf cfg.enable {
    programs.mise = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      globalConfig = mkIf (cfg.globalTools != {}) {
        tools = cfg.globalTools;
      };
    };

    # Runtimes installed by mise are pre-built binaries that expect a standard
    # FHS dynamic linker. nix-ld (enabled in hosts/common) makes that work.
    home.sessionVariables = {
      MISE_NODE_COMPILE = "0";
    };
  };
}

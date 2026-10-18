{
  config,
  lib,
  ...
}: {
  options.components.development.infrastructure.lazydocker = {
    enable = lib.mkEnableOption "lazydocker terminal UI for Docker and Docker Compose";
  };

  config = lib.mkIf config.components.development.infrastructure.lazydocker.enable {
    programs.lazydocker.enable = true;
  };
}

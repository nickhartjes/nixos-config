{
  config,
  lib,
  ...
}: {
  options.components.desktop.mangowc = {
    enable = lib.mkEnableOption "MangoWC tiling Wayland compositor";
  };

  config = lib.mkIf config.components.desktop.mangowc.enable {
    programs.mango.enable = true;
  };
}

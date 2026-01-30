{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.application.database.supabase = {
    enable = lib.mkEnableOption "Supabase CLI";
  };

  config = lib.mkIf config.components.application.database.supabase.enable {
    home.packages = with pkgs; [
      supabase-cli
    ];
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.system.gaming;
in {
  options.components.system.gaming.enable = mkEnableOption "Gaming optimizations and Steam support";

  config = mkIf cfg.enable {
    # Steam hardware udev rules for gaming devices
    hardware.steam-hardware.enable = true;

    # Gaming optimizations
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    };

    # GameMode for better gaming performance
    programs.gamemode.enable = true;

    # Graphics drivers and hardware acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = true; # Enable 32-bit graphics support for older games
    };

    # Enable realtime audio for low latency
    security.rtkit.enable = true;

    # Gaming-related packages
    environment.systemPackages = with pkgs; [
      gamemode
      gamescope # SteamOS session compositing window manager
      mangohud # Gaming overlay for monitoring performance
    ];

    # Optimize kernel for gaming
    boot.kernel.sysctl = {
      # Increase vm.max_map_count for games that need it (like some Steam games)
      "vm.max_map_count" = 2147483642;
    };
  };
}

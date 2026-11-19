{pkgs, ...}: {
  # Deliberately independent of hosts/common: WSL needs neither bootloader,
  # desktop services nor the workstation's secrets and complete application set.
  wsl.enable = true;
  wsl.defaultUser = "nh";
  networking.hostName = "wsl-t3";
  system.stateVersion = "26.05";
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  users.users.nh.linger = true;
  programs.git.enable = true;
  programs.nix-ld.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nh = {
      imports = [../../components/home-manager/application/ai/t3code.nix];
      home.stateVersion = "26.05";
      home.packages = with pkgs; [codex claude-code gh ripgrep];
      components.application.ai.t3code = {
        enable = true;
        server.enable = true;
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.cli.zsh;
in {
  options.components.cli.zsh.enable = mkEnableOption "enable zsh";

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autocd = true;
      antidote = {
        enable = true;
        plugins = [
          "zsh-users/zsh-autosuggestions"
          "romkatv/powerlevel10k"
        ];
      };
      shellAliases = {
        "..." = "cd ../..";
        ".." = "cd ..";
        grep = "rg";
        htop = "btop";
        ps = "procs";
      };
      initContent = let
        zshEarlyInit = lib.mkOrder 500 ''
          export NIX_PATH=nixpkgs=channel:nixos-unstable
          export NIX_LOG=info
        '';
        zshGeneralConfig = lib.mkOrder 1000 ''
          # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
          [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
          fastfetch
        '';
      in
        lib.mkMerge [zshEarlyInit zshGeneralConfig];
    };

    # Application needed for the zsh configuration to work properly
    home.packages = with pkgs; [
      btop
      procs
    ];

    home.file.".config/.p10k.zsh".source = ./files/.p10k.zsh;
  };
}

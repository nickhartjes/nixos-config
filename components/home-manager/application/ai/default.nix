{pkgs, ...}: {
  imports = [
    ./claude-code.nix
    ./ollama.nix
    ./alpaca.nix
    ./opencode.nix
    ./codex.nix
    ./lmstudio.nix
    ./orca.nix
    ./t3code.nix
    ./thinkrail.nix
    ./specdeck.nix
  ];
}

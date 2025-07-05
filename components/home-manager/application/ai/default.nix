{pkgs, ...}: {
  imports = [
    ./claude-code.nix
    ./ollama.nix
    ./alpaca.nix
    ./opencode.nix
    ./lmstudio.nix
  ];
}

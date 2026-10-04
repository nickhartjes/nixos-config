{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in {
  options.components.application.ai.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI assistant";
  };

  config = lib.mkIf config.components.application.ai.claude-code.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs-unstable.claude-code;

      # HM ships these as a personal plugin under ~/.claude/skills/ rather than
      # touching ~/.claude.json or settings.json, both of which Claude Code
      # rewrites at runtime. Tools show up as mcp__plugin_hm_<server>__<tool>.
      mcpServers = {
        # Live lookups of NixOS / home-manager options and packages, so option
        # names get checked instead of guessed. Pinned via nixpkgs rather than
        # `nix run github:utensils/mcp-nixos`, which would re-resolve on start.
        nixos = {
          type = "stdio";
          command = lib.getExe pkgs.mcp-nixos;
        };
      };

      # Linked individually rather than installing either repo as a plugin:
      # juspay's plugin would register a second `nixos` MCP server, and most of
      # its skills are unrelated to Nix. nix-oss-cache is left out because it
      # targets Juspay's own Attic cache.
      skills =
        lib.genAttrs [
          "nix-bun"
          "nix-ci"
          "nix-for-dev"
          "nix-haskell"
          "nix-health"
          "nix-justfile"
          "nix-perf"
          "nix-playwright"
          "nix-rust-leptos"
          "nix-typescript"
        ] (name: "${inputs.juspay-skills}/skills/${name}")
        // {
          nixos-managing = "${inputs.nixos-management-skill}/nixos-managing";
        };
    };

    # Add claude-code to allowUnfreePredicate if not globally allowed
    # nixpkgs.config = {
    #   allowUnfree = true;
    #   allowUnfreePredicate = pkg:
    #     builtins.elem (lib.getName pkg) [
    #       "claude-code"
    #       "vscode-extension-anthropic-claude-code"
    #     ];
    # };
  };
}

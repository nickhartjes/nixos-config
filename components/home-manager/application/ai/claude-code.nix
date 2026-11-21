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
    codeMode.enable = lib.mkEnableOption ''
      Claude Code's experimental Code Mode (Claude batches tool calls into a
      JavaScript snippet run by the REPL tool). Needs the native-installer
      build (~/.local/bin/claude), v2.1.323+, in an interactive terminal session.
      Note: the JS and its file/web/MCP calls run outside the sandbox'';
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

    # Set as a session variable rather than in ~/.claude/settings.json's `env`
    # block: Claude Code rewrites settings.json at runtime, so HM shouldn't own
    # it. Takes effect in new login shells (re-login after switching).
    home.sessionVariables = lib.mkIf config.components.application.ai.claude-code.codeMode.enable {
      CLAUDE_CODE_EXPERIMENTAL_CODE_MODE = "1";
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

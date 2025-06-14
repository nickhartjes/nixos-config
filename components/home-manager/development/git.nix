{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.components.development.git;
in {
  options.components.development.git = {
    enable = lib.mkEnableOption "Git version control with GPG signing";

    userName = lib.mkOption {
      type = lib.types.str;
      default = "Nick Hartjes";
      description = "Git user name";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      default = "nick@hartj.es";
      description = "Git user email";
    };

    gpgSigning = {
      enable = lib.mkEnableOption "GPG signing for commits";

      key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "GPG key ID for signing commits. If null, will use the default key.";
      };

      importFromSecrets = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to import GPG keys from agenix secrets on activation";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = cfg.userName;
      userEmail = cfg.userEmail;

      signing = lib.mkIf cfg.gpgSigning.enable {
        key = cfg.gpgSigning.key;
        signByDefault = true;
      };

      extraConfig =
        {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core.autocrlf = "input";
          rerere.enabled = true;

          # GPG configuration
          gpg.program = "${pkgs.gnupg}/bin/gpg";
        }
        // lib.optionalAttrs cfg.gpgSigning.enable {
          commit.gpgsign = true;
          tag.gpgsign = true;
        };
    };

    programs.gpg = lib.mkIf cfg.gpgSigning.enable {
      enable = true;
    };

    services.gpg-agent = lib.mkIf cfg.gpgSigning.enable {
      enable = true;
      pinentry.package = pkgs.pinentry-all;
    };

    # Import GPG keys from secrets on activation
    home.activation = lib.mkIf (cfg.gpgSigning.enable && cfg.gpgSigning.importFromSecrets) {
      importGpgKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Create .gnupg directory if it doesn't exist
        $DRY_RUN_CMD mkdir -p $HOME/.gnupg
        $DRY_RUN_CMD chmod 700 $HOME/.gnupg

        # Import private key if it exists
        if [[ -f "$HOME/.gnupg/private-key.asc" ]]; then
          $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import $HOME/.gnupg/private-key.asc 2>/dev/null || true
          echo "GPG private key imported from secrets"
        else
          echo "GPG private key not found at $HOME/.gnupg/private-key.asc - skipping import"
          echo "To set up GPG keys, see: docs/gpg-agenix-setup.md"
        fi

        # Import public key if it exists
        if [[ -f "$HOME/.gnupg/public-key.asc" ]]; then
          $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import $HOME/.gnupg/public-key.asc 2>/dev/null || true
          echo "GPG public key imported from secrets"
        else
          echo "GPG public key not found at $HOME/.gnupg/public-key.asc - skipping import"
        fi

        # Set ultimate trust for our own keys if private key was imported
        if [[ -f "$HOME/.gnupg/private-key.asc" ]]; then
          # Extract key ID from the private key and set trust
          KEY_ID=$($DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --list-secret-keys --with-colons | ${pkgs.gawk}/bin/awk -F: '/^sec:/ {print $5; exit}' 2>/dev/null || echo "")
          if [[ -n "$KEY_ID" ]]; then
            $DRY_RUN_CMD echo "$KEY_ID:6:" | ${pkgs.gnupg}/bin/gpg --batch --import-ownertrust 2>/dev/null || true
            echo "Set ultimate trust for GPG key: $KEY_ID"
          fi
        fi
      '';
    };
  };
}

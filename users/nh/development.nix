# Development tools configuration for user nh
{
  components.development = {
    mise = {
      enable = true;
      # Optional: declare global tools mise should install.
      # globalTools = {
      #   node = "lts";
      #   java = "temurin-21";
      # };
    };
    editor = {
      vscode.enable = true;
      zed.enable = true;
      intellij.enable = true;
    };
    infrastructure = {
      opentofu.enable = true;
      terraform.enable = true;
      kubernetes.enable = true;
      aws.enable = true;
      k9s.enable = true;
    };
    languages = {
      nodejs = {
        enable = true;
        playwright.enable = true;
      };
      java.enable = true;
      go.enable = true;
      rust.enable = true;
      nix.enable = true;
    };
    git = {
      enable = true;
      userName = "Nick Hartjes";
      userEmail = "nick@hartj.es";
      gpgSigning = {
        enable = true;
        key = "18D6E129BCC96ED3";
      };
    };
  };
}

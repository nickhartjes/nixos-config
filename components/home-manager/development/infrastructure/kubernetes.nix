{
  config,
  lib,
  pkgs,
  ...
}: {
  options.components.development.infrastructure.kubernetes = {
    enable = lib.mkEnableOption "Kubernetes development and operations tools";
  };

  config = lib.mkIf config.components.development.infrastructure.kubernetes.enable {
    home.packages = with pkgs; [
      kubectl # Kubernetes CLI
      kubernetes-helm # Kubernetes package manager
      k9s # Terminal UI for Kubernetes
      kubectx # Switch between Kubernetes contexts
      kustomize # Configuration management
    ];

    # All Kubernetes tools are free software, no need for allowUnfreePredicate
  };
}

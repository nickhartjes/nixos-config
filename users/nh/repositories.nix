# Repository manager configuration for user nh
{
  components.scripts = {
    repoManager = {
      enable = true;
      repositories = {
        users = {
          nh = {
            personal = [
              "git@github.com:nickhartjes/obsidian.git"
              "git@github.com:nickhartjes/dotfiles.git"
              "git@github.com:nickhartjes/nickhartjes.nl.git"
              "git@github.com:ostat/gridfinity_extended_openscad.git"
              "git@github.com:archimatetool/archi.git"
              "git@github.com:nickhartjes/nextjs-shadcn-sveltia.git"
            ];
            projects = [
              "git@github.com:nickhartjes/talos.git"
              "git@github.com:nickhartjes/gitops.git"
              "git@github.com:nickhartjes/codex.git"
            ];
            dealdodo = [
              "git@github.com:dealdodo/frontend"
              "git@github.com:dealdodo/backend"
            ];
            entrnce = [
              "git@github.com:EnergyExchangeEnablersBV/nma-platform.git"
            ];
            devops = [
              "git@github.com:EnergyExchangeEnablersBV/devops-helm-charts.git"
              "git@github.com:EnergyExchangeEnablersBV/devops-aws-cdk.git"
            ];
          };
        };
      };
    };
  };
}

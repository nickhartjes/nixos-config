{config, ...}: {
  # JA! Instituut website (github.com/nickhartjes/ja-instituut, deploy/README.md).
  # The module runs each environment as a podman container behind Caddy, with
  # a Litestream backup to Hetzner Object Storage. Releases don't touch this
  # file: CI moves the image tag and starts `podman auto-update` as `deploy`.
  #
  # DNS (Cloudflare, DNS only, so Caddy can get its own certificate):
  #   ja-instituut.hartj.es  A     2.31.128.103
  #   ja-instituut.hartj.es  AAAA  2a01:4f8:c17:4b8d::1
  #
  # The podman-auto-update timer in specdeck.nix also sees these containers
  # (same label). That is harmless: it can only pull a tag CI has already
  # moved, and CI's health check still decides whether a release succeeded.
  services.ja-instituut = {
    # Read access to the private image: a classic token with only read:packages.
    # Its expiry date goes in the ja-instituut repo's deploy/README.md (4).
    registryLogin = {
      username = "nickhartjes";
      passwordFile = config.age.secrets."ja-instituut/ghcr-token".path;
    };

    # CI's key (deploy/README.md, 5; private half in the GitHub environments).
    # It can only start the update unit.
    deploy.authorizedKeys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZw7y81w1Lea5AYuNRKdb/onmh9BjJ7fb/zXcOoHgF9 github-actions-ja-instituut"];

    instances.staging = {
      domain = "ja-instituut.hartj.es";
      port = 4401;
      environmentFile = config.age.secrets."ja-instituut/staging-env".path;
      backup = {
        enable = true;
        # TODO: the bucket you create (deploy/README.md, 3).
        bucket = "ja-instituut-backups";
        endpoint = "https://fsn1.your-objectstorage.com";
        region = "fsn1";
        # Test data only: a week of snapshots is enough.
        retention = "168h";
      };
    };

    # Later, once the owner has answered questions 2, 17 and 28:
    # instances.production = {
    #   domain = "ja-instituut.nl";
    #   port = 4402;
    #   environmentFile = config.age.secrets."ja-instituut/production-env".path;
    #   backup = {
    #     enable = true;
    #     bucket = "ja-instituut-backups";
    #     endpoint = "https://fsn1.your-objectstorage.com";
    #     region = "fsn1";
    #   };
    # };
  };
}

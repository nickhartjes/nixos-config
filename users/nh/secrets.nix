{
  age = {
    identityPaths = [
      "/home/nh/.ssh/id_ed25519"
      "/home/nh/.ssh/id_framework-13_2025-06-07"
    ];

    secrets = {
      ssh-key = {
        file = ../../secrets/nh/ssh-framework-13.age;
        path = "/home/nh/.ssh/id_framework-13_2025-06-07";
        mode = "400";
        owner = "nh";
        group = "users";
      };
      ssh-key-pub = {
        file = ../../secrets/nh/ssh-framework-13.pub.age;
        path = "/home/nh/.ssh/id_framework-13_2025-06-07.pub";
        mode = "400";
        owner = "nh";
        group = "users";
      };
      # Second SSH identity for publishing. Private key only: the public half is
      # derivable (ssh-keygen -y) and deliberately not stored. Not in the agent's
      # key list (components/home-manager/cli/ssh.nix); repos opt in via core.sshCommand.
      ssh-publish = {
        file = ../../secrets/nh/ssh-publish.age;
        path = "/home/nh/.ssh/id_publish";
        mode = "400";
        owner = "nh";
        group = "users";
      };
      # git config for repos under ~/publish/ (see the git component's includes).
      git-publish = {
        file = ../../secrets/nh/git-publish.age;
        path = "/home/nh/.config/git/publish";
        mode = "400";
        owner = "nh";
        group = "users";
      };
      gpg-private-key = {
        file = ../../secrets/nh/gpg-private-key.age;
        path = "/home/nh/.gnupg/private-key.asc";
        mode = "400";
        owner = "nh";
        group = "users";
      };
      gpg-public-key = {
        file = ../../secrets/nh/gpg-public-key.age;
        path = "/home/nh/.gnupg/public-key.asc";
        mode = "444";
        owner = "nh";
        group = "users";
      };
    };
  };
}

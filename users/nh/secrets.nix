{
  age = {
    identityPaths = ["/home/nh/.ssh/id_framework-13_2025-06-07"];

    secrets = {
      secret2 = {
        file = ../../secrets/secret1.age;
        owner = "nh";
        path = "/home/nh/.secret2";
      };
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

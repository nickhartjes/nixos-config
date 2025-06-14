{
  age = {
    identityPaths = ["/home/nh/.ssh/id_ed25519"];

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
    };
  };
}

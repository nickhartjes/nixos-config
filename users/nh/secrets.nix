{
  age = {
    identityPaths = [ "/home/nh/.ssh/id_framework-13_2025-06-07" ];
    secrets = {
      secret2 = {
        file = ../../secrets/secret1.age;
        owner = "nh";
        path = "/home/nh/.secret2";
      };
    };
  };
}

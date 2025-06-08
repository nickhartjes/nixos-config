{
  age = {
    identityPaths = [ "/home/nh/.ssh/id_framework-13_2025-06-07" ];
    secrets = {
      secret1 = {
        file = ../../secrets/secret1.age;
        path = "/home/nh/.secret1";
      };
    };
  };
}

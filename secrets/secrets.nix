let
  # Systems
  framework-13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es";
  framework-13-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es";
  systems = [framework-13];
in {
  "secret1.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  "nh/ssh-framework-13.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  "nh/ssh-framework-13.pub.age".publicKeys = [framework-13 framework-13-2] ++ systems;
}

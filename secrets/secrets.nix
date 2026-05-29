let
  # Systems
  framework-13 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPh1wLUOuMwH9tCGCRnEJ4lPqex1Ss2aaag6TKc/3hlD nick@hartj.es";
  framework-13-2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLBdQCyD8xsKKy5UIUfKS7l+Fl5RQ9yIMR3wGOfL90+ nick@hartj.es";
  velomo-alpha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeRh4DdyxTgGmDYgAaYY8yT5M0MSbRz1yGPi4P/jzWS root@velomo-alpha";
  systems = [framework-13];
  velomoSystems = [velomo-alpha];
in {
  "secret1.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  "nh/ssh-framework-13.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  "nh/ssh-framework-13.pub.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  "nh/gpg-private-key.age".publicKeys = [framework-13 framework-13-2] ++ systems;
  "nh/gpg-public-key.age".publicKeys = [framework-13 framework-13-2] ++ systems;

  "velomo-alpha/tailscale-authkey.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
  "velomo-alpha/doco-git-token.age".publicKeys = [framework-13 framework-13-2] ++ velomoSystems;
}

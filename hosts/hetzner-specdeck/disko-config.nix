{
  disko.devices = {
    disk = {
      nixos = {
        type = "disk";
        # Hetzner Cloud disk, checked on the target 2026-11-01.
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # Hetzner Cloud x86 boots legacy BIOS: GRUB needs this partition on GPT.
            boot = {
              size = "1M";
              type = "EF02";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}

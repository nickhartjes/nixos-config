{
  disko.devices = {
    disk = {
      nixos = {
        type = "disk";
        # IMPORTANT: confirm this device path on the target machine before
        # running disko. On NVMe systems it is usually /dev/nvme0n1; on
        # SATA/SCSI systems it is /dev/sda. `lsblk` on the installer ISO
        # shows the right path.
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
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

{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.virtualization.qemu;
in {
  options.components.virtualization.qemu.enable = mkEnableOption "QEMU/KVM virtualization";

  config = mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull.fd];
          };
        };
      };
      spiceUSBRedirection.enable = true;
    };

    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      win-virtio
      win-spice
      adwaita-icon-theme
    ];

    # Enable nested virtualization for Intel/AMD
    boot.extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm_amd nested=1
    '';

    # Add users to libvirtd group (configured per-user)
    users.groups.libvirtd = {};
  };
}

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./disko-config.nix
    ./hardware-configuration.nix
  ];

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.systemd-boot.configurationLimit = 15;
  boot.kernelParams = [
    # Hibernation: swapfile location on the LUKS-backed btrfs root.
    "resume=/dev/mapper/cryptroot"
    "resume_offset=2957497"

    # Audio codec runtime power saving.
    "snd_hda_intel.power_save=1"

    # Intel Wi-Fi (this board has an iwlwifi card, not the stock MediaTek).
    "iwlwifi.power_save=1"

    # Deliberately NOT set here -- see git history for why each was removed:
    #   mem_sleep_default=deep   -> /sys/power/mem_sleep only offers s2idle; no-op.
    #   acpi_osi="!Windows 2020" -> Intel-only s2idle workaround; wrong on AMD.
    #   pcie_aspm=off/force      -> were both set (contradictory); kernel default is right.
    #   amd_pstate.shared_mem=1  -> parameter removed upstream; amd_pstate is built-in.
    #   processor.max_cstate=9   -> above the real C-state count; no-op.
    #   nordrand                 -> Zen 3-era RDRAND quirk, not applicable to Zen 5.
    #   snd_ac97_codec.power_save -> no AC97 codec on this hardware.
    #
    # amd_pstate=active and amdgpu.dcdebugmask=0x10 (PSR hang fix) come from
    # nixos-hardware's framework-amd-ai-300-series module -- do not duplicate them.
  ];
  boot.resumeDevice = "/dev/mapper/cryptroot";

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # Track the latest mainline kernel. We were previously pinned to 6.12 LTS for
  # evdi/DisplayLink, but 6.12 left the USB-C controller without renegotiating
  # DisplayPort after resume, killing external displays until a physical replug.
  # DisplayLink is disabled (hosts/framework-13/default.nix), so there's no reason
  # to pin to an LTS — newer kernels carry better Framework/AMD hardware support.
  # If DisplayLink is needed again, pin back to an evdi-supported kernel here and
  # re-enable it.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable hibernation support
  boot.kernelModules = ["btrfs"];
  boot.initrd.supportedFilesystems = ["btrfs"];

  # Power management is power-profiles-daemon, enabled by nixos-hardware's
  # framework-amd-ai-300-series module. AMD Framework laptops get better battery
  # life from PPD than TLP (https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13),
  # and Plasma's power-profile switcher drives PPD over D-Bus.
  #
  # auto-cpufreq was removed: it duplicated what amd-pstate-epp already does in
  # firmware, and left Plasma's power UI inert.

  powerManagement = {
    enable = true;
    powertop.enable = true;
    # No cpuFreqGovernor: amd-pstate-epp only exposes performance/powersave, so
    # cpufreq.service failed on every boot trying to set "ondemand".
    scsiLinkPolicy = "med_power_with_dipm";
  };

  # Automatically follow the AC adapter, because power-profiles-daemon does not
  # do this itself: 0.30 ships no udev rules and only the cookie-based
  # HoldProfile D-Bus API, so *something* has to drive it. Plasma (powerdevil)
  # and COSMIC do; a bare niri/mango session does not, which would otherwise
  # leave us pinned to "balanced" forever -- a regression versus auto-cpufreq.
  #
  # Setting the same profile a desktop would pick keeps this harmless when a
  # desktop is also managing it. Change onAC to "performance" for the old
  # auto-cpufreq behaviour.
  systemd.services.power-profile-auto = let
    ppd = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";
    onAC = "balanced";
    onBattery = "power-saver";
  in {
    description = "Select a power profile based on AC adapter state";

    # Upstream's PPD unit is `After=multi-user.target` -- it is designed to be
    # D-Bus-activated late in boot. Hooking this follower into multi-user.target
    # therefore forms an ordering cycle (a target implicitly gains After= on
    # everything it Wants=), and systemd breaks it by dropping PPD, leaving the
    # daemon unactivatable. graphical.target is ordered after both
    # multi-user.target and the display manager, so the chain resolves.
    wantedBy = ["graphical.target"];
    after = ["power-profiles-daemon.service"];
    wants = ["power-profiles-daemon.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "power-profile-auto" ''
        online=$(cat /sys/class/power_supply/ACAD/online 2>/dev/null || echo 1)
        if [ "$online" = "1" ]; then target=${onAC}; else target=${onBattery}; fi
        [ "$(${ppd} get)" = "$target" ] || ${ppd} set "$target"
      '';
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="ACAD", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart power-profile-auto.service"
  '';

  # Additional hibernation and power optimizations
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandlePowerKey = "hibernate";
    HandlePowerKeyLongPress = "poweroff";
    HandleSuspendKey = "suspend-then-hibernate";
    HandleHibernateKey = "hibernate";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "2h";
  };

  # nixos-hardware's laptop module enables TLP whenever PPD is off; keep it
  # explicitly disabled so the two never fight.
  services.tlp.enable = false;

  # Framework firmware updates
  services.fwupd.enable = true;

  # Speaker tuning (bass extension, loudness compensation, EQ, compression).
  # nixos-hardware already sets rawDeviceName for this exact board.
  hardware.framework.laptop13.audioEnhancement.enable = true;

  # Enable the UCodeNix service for CPU microcode updates
  # services.ucodenix = {
  #   enable = true;
  #   cpuModelId = "00B60F00"; #  AMD Ryzen AI 5 340
  #   # cpuModelId = ./facter.json;
  # };
  # old: [    0.437076] microcode: Current revision: 0x0b60000e

  hardware.bluetooth.enable = true; # enables support for Bluetooth
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot

  networking.hostName = "framework-13"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager = {
    enable = true;
    plugins = with pkgs; [
      networkmanager-openvpn
    ];
  };
  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nl_NL.UTF-8";
    LC_IDENTIFICATION = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_NAME = "nl_NL.UTF-8";
    LC_NUMERIC = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
    LC_TELEPHONE = "nl_NL.UTF-8";
    LC_TIME = "nl_NL.UTF-8";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim
    sbctl # Secure Boot Control
    git
    wireguard-tools

    powertop
    acpi
    lm_sensors
    amd-debug-tools # provides amd-s2idle / amd-pstate / amd-bios diagnostics
    linuxPackages.turbostat
    cpufrequtils
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable PipeWire for audio management
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = false;
    settings.PermitRootLogin = "no";
    allowSFTP = false;
  };

  programs.zsh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  #security.sudo.wheelNeedsPassword = false;

  security.sudo.extraConfig = "nh ALL=(ALL) NOPASSWD: ALL";

  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

  system = {
    autoUpgrade = {
      enable = true;
      flake = "path:/home/nh/.config/nixos-config";
      flags = [
        "--commit-lock-file"
      ];
      dates = "weekly";
    };
  };

  # # Disable PCIe wakeup for AMD devices to prevent issues with suspend/hibernate
  # services.udev.extraRules = ''
  #   # Disable wakeup for specific USB controllers
  #   SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x43f3", ATTR{power/wakeup}="disabled"
  #   SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x43f4", ATTR{power/wakeup}="disabled"

  #   # Disable wakeup for specific Thunderbolt controllers
  #   SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x43f5", ATTR{power/wakeup}="disabled"
  #   SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x43f6", ATTR{power/wakeup}="disabled"
  # '';

  # # Manage wireless devices during suspend
  # systemd.services.rfkill-suspend = {
  #   description = "Disable Wi-Fi and Bluetooth before suspend";
  #   before = ["sleep.target"];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "/usr/sbin/rfkill block all";
  #     ExecStop = "/usr/sbin/rfkill unblock all";
  #   };
  #   wantedBy = ["sleep.target"];
  # };

  # Convenient aliases for power management / thermals
  environment.shellAliases = {
    "cpu-perf" = "powerprofilesctl set performance";
    "cpu-save" = "powerprofilesctl set power-saver";
    "cpu-auto" = "powerprofilesctl set balanced";
    "cpu-stats" = "powerprofilesctl get";
    "fw-power" = "sudo powertop";
    "fw-temp" = "sensors";
    "fw-s2idle" = "sudo amd-s2idle"; # AMD suspend diagnostics
    "fw-freq" = "cpufreq-info";
  };

  systemd.services."networkmanager-resume" = {
    description = "Restart NetworkManager and reload iwlwifi after resume";
    wantedBy = ["sleep.target"];
    after = ["sleep.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/modprobe -r iwlwifi; ${pkgs.systemd}/bin/modprobe iwlwifi; ${pkgs.systemd}/bin/systemctl restart NetworkManager";
    };
  };
}

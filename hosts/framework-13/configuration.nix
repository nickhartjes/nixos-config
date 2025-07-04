# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
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
    "resume=/dev/mapper/cryptroot" # Path to the swap partition for hibernation
    "resume_offset=2957497" # Offset for the swap partition, adjust as needed
    "mem_sleep_default=deep" # Use deep sleep for better power management
    "pcie_aspm=off" # Disable PCIe Active State Power Management
    "acpi_osi=\"!Windows 2020\"" # Addresses ACPI-related issues that can affect suspend behavior.

    # Additional power management beyond what nixos-hardware provides
    "processor.max_cstate=9"
    "amd_pstate.shared_mem=1"

    # Audio power saving
    "snd_hda_intel.power_save=1"
    "snd_ac97_codec.power_save=1"

    # Network power management
    "iwlwifi.power_save=1"

    # Additional power saving
    "pcie_aspm=force"
  ];
  boot.resumeDevice = "/dev/mapper/cryptroot";

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # Enable hibernation support
  boot.kernelModules = ["btrfs"];
  boot.initrd.supportedFilesystems = ["btrfs"];

  # Automatically adjust CPU frequency based on system load
  programs.auto-cpufreq = {
    enable = true;

    settings = {
      # AC Power / Charger settings
      charger = {
        governor = "performance";

        # AMD Ryzen AI 5 340: Base 2.0GHz, Boost 4.2GHz
        scaling_min_freq = 2000000; # 2.0 GHz
        scaling_max_freq = 4200000; # 4.2 GHz max boost

        # Enable turbo boost for AC power
        turbo = "auto";

        # Energy Performance Preference
        energy_performance_preference = "performance";

        # Battery threshold management for AC use
        enable_thresholds = true;
        start_threshold = 20;
        stop_threshold = 95;
      };

      # Battery power settings
      battery = {
        governor = "powersave";

        # Conservative frequencies for battery efficiency
        scaling_min_freq = 400000; # 400 MHz minimum
        scaling_max_freq = 2000000; # 2.0 GHz (below base for efficiency)

        # Disable turbo on battery to maximize life
        turbo = "never";

        # Power-focused EPP
        energy_performance_preference = "power";

        # Battery-optimized charging thresholds
        enable_thresholds = true;
        start_threshold = 15;
        stop_threshold = 80; # Conservative limit for longevity
      };
    };
  };

  services.power-profiles-daemon.enable = false;

  powerManagement = {
    enable = true;
    powertop.enable = true;
    cpuFreqGovernor = "ondemand"; # Fallback governor if auto-cpufreq
    scsiLinkPolicy = "med_power_with_dipm";
  };

  # Suspend first then hibernate when closing the lid
  services.logind.lidSwitch = "suspend-then-hibernate";
  # Hibernate on power button pressed
  services.logind.powerKey = "hibernate";
  services.logind.powerKeyLongPress = "poweroff";

  # Define time delay for hibernation
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';

  # Additional hibernation and power optimizations
  services.logind.extraConfig = ''
    HandleSuspendKey=suspend-then-hibernate
    HandleHibernateKey=hibernate
    IdleAction=suspend-then-hibernate
    IdleActionSec=2h
  '';

  # Optimize for Framework laptop
  services.tlp = {
    enable = false; # Disabled since we're using power-profiles-daemon
  };

  # Framework firmware updates
  services.fwupd.enable = true;

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
  networking.networkmanager.enable = true;
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

    powertop
    acpi
    lm_sensors
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
  system.stateVersion = "24.11"; # Did you read the comment?

  system = {
    # Allow auto update
    autoUpgrade = {
      enable = true;
      flake = "path:/home/nh/.config/nixos-config";
      flags = [
        "--commit-lock-file"
        "--recreate-lock-file"
      ];
      dates = "daily";
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

  # Convenient aliases for auto-cpufreq management
  environment.shellAliases = {
    "cpu-perf" = "sudo auto-cpufreq --force=performance";
    "cpu-save" = "sudo auto-cpufreq --force=powersave";
    "cpu-auto" = "sudo auto-cpufreq --force=reset";
    "cpu-stats" = "auto-cpufreq --stats";
    "cpu-monitor" = "auto-cpufreq --monitor";
    "cpu-live" = "sudo auto-cpufreq --live";
    "fw-power" = "sudo powertop";
    "fw-temp" = "sensors";
    "fw-freq" = "cpufreq-info";
  };
}

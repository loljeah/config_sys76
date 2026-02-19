# NixOS Configuration - Sway (Wayland)
# System76 Serval WS 13 (serw13) - Intel i9-14900HX + NVIDIA RTX 4060 Mobile

{ config, pkgs, lib, ... }:

let
  signal-desktop-desktopitem = pkgs.makeDesktopItem {
    name = "signal-desktop";
    desktopName = "Signal";
    exec = "${pkgs.signal-desktop}/bin/signal-desktop %U";
    icon = "signal-desktop";
    type = "Application";
    terminal = false;
    categories = [ "Network" "InstantMessaging" "Chat" ];
    mimeTypes = [ "x-scheme-handler/sgnl" "x-scheme-handler/signalcaptcha" ];
    startupWMClass = "Signal";
  };

in
{
  imports =
    [
      ./hardware-configuration.nix
      ./undervolt.nix
    ];

  #####################################################################
  # SYSTEM76 HARDWARE SUPPORT
  #####################################################################
  hardware.system76 = {
    enableAll = true;  # Enables firmware-daemon, kernel-modules, power-daemon
    # Individual options if needed:
     firmware-daemon.enable = true;
     kernel-modules.enable = true;
     power-daemon.enable = true;
  };

  # System76 Open Firmware / Coreboot support
  # ec_sys.write_support needed for system76-driver
  boot.kernelParams = [
    "ec_sys.write_support=1"

    # Intel i9-14900HX optimizations
    "intel_pstate=active"             # Use Intel P-State driver for best performance
    "i915.enable_guc=3"               # Enable GuC/HuC for Intel iGPU
    "i915.enable_fbc=1"               # Frame buffer compression (power saving)
    "i915.fastboot=1"                 # Faster boot with Intel graphics

    # NVIDIA
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # Better suspend/resume
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"        # Temp files for power mgmt

    # Low-latency gaming optimizations
    "preempt=full"                    # Full kernel preemption (lower latency)
    "threadirqs"                      # Threaded IRQ handlers
    "tsc=reliable"                    # Trust TSC for timekeeping
    "clocksource=tsc"                 # Use TSC clocksource (lowest latency)

    # Memory
    "transparent_hugepage=madvise"    # THP on-demand (better for mixed workloads)

    # Power saving
    "nmi_watchdog=0"                  # Disable NMI watchdog (saves power, loses crash debug)

    # Hibernate resume from swapfile
    "resume_offset=11255808"

    # Security note: mitigations=off removed for security on a laptop
    # Uncomment if you need max gaming performance and accept the risk:
    # "mitigations=off"
  ];

  #####################################################################
  # NVIDIA RTX 4060 Mobile + Intel iGPU (PRIME Offload)
  #####################################################################

  # Graphics - Intel iGPU + NVIDIA dGPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # Required for Wine/Proton 32-bit games

    extraPackages = with pkgs; [
      # Intel iGPU (UHD Graphics for 14th gen)
      intel-media-driver    # VAAPI driver for Intel (iHD)
      intel-compute-runtime # OpenCL for Intel
      vpl-gpu-rt           # Intel Video Processing Library

      # VA-API utilities
      libva
      libva-utils
      libvdpau-va-gl
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      libva
    ];
  };

  # NVIDIA driver configuration
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Use proprietary modules (open modules may not build with latest kernel)
    # Set to true once NVIDIA open modules support your kernel version
    open = false;

    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Power management for laptop - critical for battery life
    powerManagement.enable = true;
    # Fine-grained power management (turns off GPU when not in use)
    # Requires Turing or newer (RTX 20/30/40 series)
    powerManagement.finegrained = true;

    # Use the stable driver branch (works well with RTX 4060)
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # NVIDIA settings GUI
    nvidiaSettings = true;

    # PRIME Offload Mode - Intel iGPU primary, NVIDIA on-demand
    # This saves battery by keeping NVIDIA GPU asleep until needed
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Provides nvidia-offload command
      };

      # ============================================================
      # IMPORTANT: Find your actual PCI Bus IDs by running:
      #   nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D'"
      #
      # Convert hex to decimal: 0000:00:02.0 -> PCI:0:2:0
      # ============================================================
      # Typical System76 Serval WS layout:
      intelBusId = "PCI:0:2:0";      # Intel UHD Graphics
      nvidiaBusId = "PCI:1:0:0";     # NVIDIA RTX 4060 Mobile
    };
  };

  # Hardware acceleration environment variables
  environment.sessionVariables = {
    # Intel iGPU VA-API
    LIBVA_DRIVER_NAME = "iHD";
    # Let apps auto-detect Wayland
    NIXOS_OZONE_WL = "1";
    DEFAULT_BROWSER = "chromium";
    # NVIDIA Wayland support
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";  # Fix cursor issues on NVIDIA
    # Clear conflicting preloads
    LD_PRELOAD = "";
  };


  #####################################################################
  # BOOTLOADER & KERNEL
  #####################################################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Resume from hibernate (swapfile)
  boot.resumeDevice = "/dev/disk/by-uuid/f72c91bc-5dcd-4463-ac9d-a545bdeac61e";

  # Stable kernel with good NVIDIA driver support
  # Use linuxPackages_latest once NVIDIA drivers catch up
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.kernelModules = [
    "v4l2loopback"
    "ntfs3"
    "kvm-intel"       # KVM for Intel
    "coretemp"        # CPU temperature monitoring
  ];

  boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];

  # aarch64 emulation for cross-compiling/chroot (e.g., Raspberry Pi images)
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };

  # Support user mounts
  boot.supportedFilesystems = [ "ntfs" "exfat" "vfat" "ext4" "btrfs" ];

  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  #####################################################################
  # NIX STORE & BINARY CACHE HARDENING
  #####################################################################
  nix.settings = {
    # Enable modern Nix features
    experimental-features = [ "nix-command" "flakes" ];

    # ─── Signature Verification (MITM Protection) ───────────────────
    # Require cryptographic signatures on all substituted paths
    require-sigs = true;

    # Only trust official NixOS cache signing key
    # Add additional keys here if using extra caches (e.g., cachix)
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # ─── Substituter Restrictions ────────────────────────────────────
    # Only use official HTTPS cache (encrypted transport)
    substituters = [ "https://cache.nixos.org" ];

    # No additional caches allowed by unprivileged users
    trusted-substituters = [ ];

    # ─── User Access Control ─────────────────────────────────────────
    # Restrict who can connect to nix-daemon
    allowed-users = [ "@wheel" ];

    # CRITICAL: trusted-users can bypass security checks
    # Adding users here is equivalent to giving them root access
    trusted-users = [ "root" ];

    # ─── Build Sandbox (Defense in Depth) ────────────────────────────
    # Isolate builds from host filesystem
    sandbox = true;

    # Fail if sandbox unavailable (don't silently disable)
    sandbox-fallback = false;

    # Block privilege escalation inside builds
    allow-new-privileges = false;

    # Filter dangerous syscalls in sandbox
    filter-syscalls = true;

    # ─── Additional Hardening ────────────────────────────────────────
    # Restrict evaluation-time builds (breaks some packages if false)
    # allow-import-from-derivation = false;  # Uncomment for stricter security

    # Auto-optimize store to save disk space
    auto-optimise-store = true;
  };

  networking.hostName = "ax76";
  networking.networkmanager.enable = true;

  # OpenConnect VPN support (Cisco AnyConnect compatible)
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  # Time zone
  time.timeZone = "Europe/Vienna";

  # Internationalisation
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

  #####################################################################
  # POWER MANAGEMENT (Laptop)
  #####################################################################

  # Thermald for Intel CPU thermal management
  services.thermald.enable = true;

  # TLP for laptop power management
  # Note: System76 power-daemon handles profiles (battery/balanced/performance)
  # TLP handles the fine-grained settings that System76 doesn't cover
  services.tlp = {
    enable = true;
    settings = {
      # ─────────────────────────────────────────────────────────────
      # CPU - Let System76 power-daemon handle governor via profiles
      # These are fallbacks / additional tuning
      # ─────────────────────────────────────────────────────────────
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Intel HWP (Hardware P-states) - 14th gen i9
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # Turbo boost - HUGE power saver when disabled on battery
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # CPU frequency limits on battery (i9-14900HX: 2.2GHz base, 5.8GHz turbo)
      # Limiting max freq on battery saves significant power
      # CPU_SCALING_MAX_FREQ_ON_BAT = 2200000;  # Uncomment for aggressive saving

      # Platform profile (modern Intel - power/balanced/performance)
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      # ─────────────────────────────────────────────────────────────
      # Intel GPU (iGPU) frequency limits - saves power on battery
      # ─────────────────────────────────────────────────────────────
      INTEL_GPU_MIN_FREQ_ON_AC = 0;        # Driver default
      INTEL_GPU_MIN_FREQ_ON_BAT = 0;       # Driver default (lowest)
      INTEL_GPU_MAX_FREQ_ON_AC = 0;        # Driver default (max)
      INTEL_GPU_MAX_FREQ_ON_BAT = 800;     # Limit to 800MHz on battery
      INTEL_GPU_BOOST_FREQ_ON_AC = 0;      # Driver default
      INTEL_GPU_BOOST_FREQ_ON_BAT = 800;   # Limit boost on battery

      # ─────────────────────────────────────────────────────────────
      # PCIe / ASPM (Active State Power Management)
      # ─────────────────────────────────────────────────────────────
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # ─────────────────────────────────────────────────────────────
      # Runtime Power Management (for devices like NVIDIA dGPU)
      # ─────────────────────────────────────────────────────────────
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # Exclude NVIDIA GPU from TLP's runtime PM (handled by nvidia.powerManagement)
      # Get device ID with: lspci -nn | grep -i nvidia
      # RUNTIME_PM_DENYLIST = "01:00.0";  # Uncomment if NVIDIA PM conflicts

      # ─────────────────────────────────────────────────────────────
      # Storage - NVMe/SSD power management
      # ─────────────────────────────────────────────────────────────
      # AHCI link power management
      SATA_LINKPWR_ON_AC = "med_power_with_dipm";
      SATA_LINKPWR_ON_BAT = "min_power";

      # NVMe - APM levels (1=min power, 254=max performance)
      DISK_APM_LEVEL_ON_AC = "254 254";
      DISK_APM_LEVEL_ON_BAT = "128 128";

      # I/O scheduler (mq-deadline good for NVMe)
      DISK_IOSCHED = "mq-deadline mq-deadline";

      # ─────────────────────────────────────────────────────────────
      # USB autosuspend - suspends idle USB devices
      # ─────────────────────────────────────────────────────────────
      USB_AUTOSUSPEND = 1;
      # Exclude input devices (mouse, keyboard) from autosuspend
      USB_DENYLIST = "usbhid";
      # Or exclude specific devices by ID: USB_DENYLIST = "1234:5678 abcd:efgh"

      # ─────────────────────────────────────────────────────────────
      # WiFi power management
      # ─────────────────────────────────────────────────────────────
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # ─────────────────────────────────────────────────────────────
      # Audio power save - powers down codec after idle
      # ─────────────────────────────────────────────────────────────
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";  # Also suspend controller

      # ─────────────────────────────────────────────────────────────
      # Misc power saving
      # ─────────────────────────────────────────────────────────────
      # NMI watchdog - disable for power saving (loses crash debugging)
      NMI_WATCHDOG = 0;

      # Wake-on-LAN - disable to save power
      WOL_DISABLE = "Y";

      # ─────────────────────────────────────────────────────────────
      # Battery charge thresholds (if supported by System76)
      # Limiting charge to 80% extends battery lifespan significantly
      # Check support: tlp-stat -b
      # ─────────────────────────────────────────────────────────────
      # START_CHARGE_THRESH_BAT0 = 75;
      # STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Disable power-profiles-daemon (conflicts with TLP and system76-power)
  services.power-profiles-daemon.enable = false;

  # Lid close behavior: suspend, then hibernate after 5 minutes
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";  # Just suspend when plugged in
    HandleLidSwitchDocked = "ignore";          # Ignore when external monitor connected
    HandlePowerKey = "suspend";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "15min";
  };

  # Suspend-then-hibernate timing
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    HibernateDelaySec=5min
  '';

  # Swapfile for hibernation (adjust size to match your RAM)
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024;  # 32GB in MB - adjust to your RAM size
  }];

  # ACPID for lid events (keyboard LED script removed)
  services.acpid.enable = true;

  # Security
  security.polkit.enable = true;
  security.rtkit.enable = true;

  # Passwordless sudo for System76 power management
  security.sudo.extraRules = [
    {
      users = [ "ljsm" ];
      commands = [
        { command = "${pkgs.system76-power}/bin/system76-power *"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  # NOTE: Keyboard LED and GPU power control now handled via udev rules (see below)
  # No passwordless sudo needed - udev sets MODE="0666" on these sysfs paths

  # Required for Sway
  security.pam.services.swaylock = {};
  security.pam.services.hyprlock = {};

  # GNOME Keyring disabled - not using VS Code Remote-SSH anymore
  services.gnome.gnome-keyring.enable = false;

  # iOS device support
  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  # Firmware updates (fwupd) - important for System76
  services.fwupd = {
    enable = true;
    # Block custom BIOS/EC firmware from being overwritten
    # Find device IDs with: fwupdmgr get-devices
    daemonSettings = {
      DisabledDevices = [
        # Uncomment and add your device GUIDs after running:
        # fwupdmgr get-devices | grep -i "device id"
        # "GUID-OF-SYSTEM-FIRMWARE"
        # "GUID-OF-EC-FIRMWARE"
      ];
    };
  };

  # USBGuard - USB device authorization policy
  # See commands below to generate initial rules before enabling
  services.usbguard = {
    enable = true;
    presentDevicePolicy = "apply-policy";  # Apply policy to already-connected devices
    implicitPolicyTarget = "block";         # Block unknown devices by default
    # rules will be in /var/lib/usbguard/rules.conf after generation
  };

  #####################################################################
  # PRINTING & SCANNING
  #####################################################################

  # CUPS printing
  services.printing = {
    enable = true;
    # Network printer discovery
    browsing = true;
    defaultShared = false;  # Don't share printers from this machine

    # Printer drivers
    drivers = with pkgs; [
      # Generic drivers (work with most PostScript/PCL printers)
      cups-filters        # IPP Everywhere / driverless + generic PS/PCL
      ghostscript         # PostScript interpreter

      # Foomatic database (large driver collection)
      foomatic-db
      foomatic-db-ppds
      foomatic-db-nonfree

      # Gutenprint (wide coverage)
      gutenprint
      gutenprintBin

      # Manufacturer-specific
      hplip               # HP
      brlaser             # Brother laser
      brgenml1lpr         # Brother generic
      brgenml1cupswrapper
      epson-escpr         # Epson
      epson-escpr2
      splix               # Samsung/Xerox
      cnijfilter2         # Canon
    ];
  };

  # Avahi for network printer/scanner discovery (mDNS/Bonjour)
  services.avahi = {
    enable = true;
    nssmdns4 = true;       # Enable mDNS name resolution
    openFirewall = false;  # Security: don't open firewall globally
                           # mDNS works on trusted LANs; use allowedUDPPorts if needed
    publish = {
      enable = false;      # Don't advertise this machine
      userServices = false;
    };
    # Only allow mDNS reflector on specific interfaces if needed:
    # reflector = true;
    # allowInterfaces = [ "eth0" ];
  };

  # SANE scanning support
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan         # Driverless scanning (AirScan/eSCL/WSD)
      hplipWithPlugin      # HP scanner support
      epkowa               # Epson scanners
    ];
    brscan4 = {
      enable = true;       # Brother scanner driver (brscan4)
      netDevices = {
        mfc9320cw = {
          model = "MFC-9320CW";
          ip = "192.168.1.100";  # UPDATE: Set your printer's IP address
        };
      };
    };
  };

  # PipeWire audio
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Thumbnail support for Thunar
  services.tumbler.enable = true;

  # USB/SD card automounting
  services.gvfs.enable = true;
  services.udisks2 = {
    enable = true;
    mountOnMedia = true;
    settings = {
      "udisks2.conf" = {
        defaults = {
          auth_admin_keep = "always";
        };
        udisks2 = {
          modules = [ "*" ];
          modules_load_preference = "ondemand";
        };
      };
    };
  };

  # Polkit rules for passwordless mounting of REMOVABLE media only
  # System mounts require password for security
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      /* Only allow passwordless mount/unmount for removable media (USB, SD cards) */
      if ((action.id == "org.freedesktop.udisks2.filesystem-mount" ||
           action.id == "org.freedesktop.udisks2.filesystem-unmount-others" ||
           action.id == "org.freedesktop.udisks2.eject-media" ||
           action.id == "org.freedesktop.udisks2.power-off-drive" ||
           action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
           action.id == "org.freedesktop.udisks2.loop-setup") &&
          subject.isInGroup("wheel") &&
          subject.local &&
          subject.active) {
        return polkit.Result.YES;
      }
    });

    /* System mounts, other-seat mounts, and disk modification require password */
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
           action.id == "org.freedesktop.udisks2.filesystem-mount-other-seat" ||
           action.id == "org.freedesktop.udisks2.encrypted-unlock-system" ||
           action.id == "org.freedesktop.udisks2.modify-device" ||
           action.id == "org.freedesktop.udisks2.modify-device-system" ||
           action.id == "org.freedesktop.udisks2.rescan" ||
           action.id == "org.freedesktop.udisks2.ata-smart-update" ||
           action.id == "org.freedesktop.udisks2.ata-smart-simulate") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
      }
    });
  '';

  # Udev rules for proper permissions on removable media
  services.udev.extraRules = ''
    # Allow users in storage/plugdev group to access removable media
    SUBSYSTEM=="block", ENV{ID_FS_USAGE}=="filesystem", GROUP="users", MODE="0660"
    # USB drives
    KERNEL=="sd[a-z]*", SUBSYSTEMS=="usb", GROUP="users", MODE="0660"
    # SD cards
    KERNEL=="mmcblk[0-9]*", SUBSYSTEMS=="mmc", GROUP="users", MODE="0660"

    # System76 power profile auto-switching on AC/battery change
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.system76-power}/bin/system76-power profile battery"
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.system76-power}/bin/system76-power profile balanced"

    # System76 keyboard backlight - allow video group to control
    SUBSYSTEM=="leds", KERNEL=="system76_acpi::kbd_backlight", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/system76_acpi::kbd_backlight/brightness /sys/class/leds/system76_acpi::kbd_backlight/color"

    # NVIDIA GPU runtime power management - allow video group
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys%p/power/control", GROUP="video"
  '';

  # PlatformIO udev rules for USB programmers (Arduino, ESP, STM32, etc.)
  services.udev.packages = [ pkgs.platformio-core.udev ];

  # Allow FUSE user mounts
  programs.fuse.userAllowOther = true;

  # D-Bus (required for many Wayland components)
  services.dbus.enable = true;

  # XDG portal for Wayland screen sharing, file dialogs, etc.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    terminus_font
    terminus_font_ttf
    roboto
    roboto-mono
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    iosevka
    ibm-plex
    source-code-pro
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Terminus" ];
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      gamemode
      pkgsi686Linux.gamemode
    ];
  };

  # User account
  users.users.ljsm = {
    isNormalUser = true;
    description = "ljsm";
    # Groups: wheel=sudo, video=GPU/brightness, libvirtd/kvm=VMs, scanner/lp=printing
    # Note: docker group removed - using rootless Docker instead
    extraGroups = [ "networkmanager" "wheel" "dialout" "plugdev" "video" "storage" "users" "render" "libvirtd" "kvm" "scanner" "lp" ];
    packages = with pkgs; [
      # Development / Editors
      helix              # Modern modal editor - native, fast, built-in LSP
      neovim             # Highly extensible, large ecosystem
      arduino
      arduino-ide
      nodejs_22
      gh
      platformio-core
      avrdude
      esptool
      zlib
      libusb1

      # AI-CODE
      claude-code

      # Sync / Cloud
      nextcloud-client

      # Office / Productivity
      libreoffice
      keepassxc
      calibre
      thunderbird

      # Graphics / 3D
      openscad
      gimp
      orca-slicer
      cura

      # Media
      vlc
      handbrake
      losslesscut-bin
      audacity
      yt-dlp
      streamripper

      # Internet / Communication
      remmina
      magic-wormhole

      # Matrix Chat
      fractal          # GTK4/Rust Matrix client with E2EE (uses secure vodozemac)

      # Gaming / Emulation
 #     lutris
 #     wine
 #     winetricks
 #     mangohud
 #     wine-wayland
 #     dxvk
 #     umu-launcher
      nvtopPackages.full  # NVIDIA GPU monitoring (replaces lact for AMD)

      # System utilities
      gparted
      gnome-disk-utility
      woeusb
      woeusb-ng
      rsync
      bleachbit
      hashrat

      # Networking
      wireshark
      nmap
      wg-netmanager
      winbox
      minicom

      # Archive tools
      unzip
      unrar
      rar
      p7zip
      xarchiver

      # Security
      yubioath-flutter

      # iOS
      libimobiledevice

      # Printing & Scanning GUI tools
      system-config-printer  # GTK printer setup (Wayland-compatible)
      simple-scan            # Easy scanner GUI (GNOME Simple Scan)

      # Misc
      calc
      deskflow
      checkmate
      nix-bash-completions
      bash-completion

      # System76 tools
      system76-firmware
      firmware-manager
      system76-keyboard-configurator  # Keyboard backlight customization

      # ===== Wayland-specific =====

      grim
      slurp
      swappy
      wdisplays
      rofi
      mako
      foot
      wl-clipboard
      cliphist
      swaylock
      swayidle
      brightnessctl
      pamixer
      playerctl
      pwvucontrol
      networkmanagerapplet
      swaybg
      imv
      zathura
      file-roller
      p7zip
      unrar
      unar
      libarchive
      wev
      wlr-randr
      bandwhich
      nethogs
      hyprlock
      udiskie
    ];
  };

  # Thunar file manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
      thunar-media-tags-plugin
    ];
  };
  programs.xfconf.enable = true;

  # Sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraOptions = [ "--unsupported-gpu" ];  # Required for NVIDIA proprietary drivers
    extraPackages = with pkgs; [
      swaylock
      swayidle
      swaybg
      waybar
      wl-clipboard
      mako
      grim
      slurp
      foot
      rofi
    ];
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      # NVIDIA Wayland support
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export WLR_NO_HARDWARE_CURSORS=1
    '';
  };

  programs.dconf.enable = true;

  # Gamescope compositor for gaming
  programs.gamescope = {
    enable = true;
    capSysNice = false;
  };

  # Gamemode for better gaming performance
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
        softrealtime = "auto";
        ioprio = 0;
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        # NVIDIA doesn't use amd_performance_level
        nv_powermizer_mode = 1;  # Prefer maximum performance
      };
      cpu = {
        park_cores = "no";
        pin_cores = "yes";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Performance mode enabled'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Performance mode disabled'";
      };
    };
  };

  # Bash configuration
  programs.bash = {
    completion.enable = true;
    shellAliases = {
      # Editor aliases - nano user transition
      nano = "nvim";
      n = "nvim";
      nv = "nvim";
      vi = "nvim";
      vim = "nvim";
      hx = "helix";
      h = "helix";

      # Quick edit shortcuts
      edit = "nvim";
      e = "nvim";

      # Common file operations
      ll = "ls -lah";
      la = "ls -la";
      l = "ls -CF";

      # Safety aliases
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline -20";
      gd = "git diff";

      # System
      reload = "source ~/.bashrc";
      cls = "clear";

      # NixOS
      nrs = "echo 'Run: sudo nixos-rebuild switch'";
      nrt = "echo 'Run: sudo nixos-rebuild test'";

      # Quick config edit
      nixconf = "nvim /home/ljsm/gitZ/config_sys76/configuration.nix";

      # USBGuard aliases
      usb-list = "sudo usbguard list-devices";
      usb-allow = "sudo usbguard allow-device";
      usb-block = "sudo usbguard block-device";
      usb-reject = "sudo usbguard reject-device";
      usb-rules = "sudo usbguard list-rules";
      usb-gen = "sudo usbguard generate-policy";

      # System76 power profile aliases
      power-battery = "sudo system76-power profile battery && echo 'Switched to Battery profile'";
      power-balanced = "sudo system76-power profile balanced && echo 'Switched to Balanced profile'";
      power-performance = "sudo system76-power profile performance && echo 'Switched to Performance profile'";
      power-status = "system76-power profile";
      power-charge = "system76-power charge-thresholds";

      # SSH key management aliases
      ssh-keys = "ssh-add -l";
      ssh-load = "ssh-add";
      ssh-unload = "ssh-add -D";
    };
  };

  # Default applications (MIME types)
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "text/html" = "chromium-browser.desktop";
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
      "x-scheme-handler/about" = "chromium-browser.desktop";
      "x-scheme-handler/unknown" = "chromium-browser.desktop";
      "application/xhtml+xml" = "chromium-browser.desktop";
    };
  };

  environment.etc."xdg/xfce4/helpers.rc".text = ''
    TerminalEmulator=foot
  '';

  # Docker - rootless mode for security (no root daemon)
  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;  # Sets DOCKER_HOST for user
    };
    # Disable root daemon since we're using rootless
    daemon.settings = { };
  };

  # Libvirt / QEMU / KVM
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;  # Security: run QEMU as user, not root
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  #####################################################################
  # BROWSERS - Hardware acceleration + DRM (Widevine) configuration
  #####################################################################

  # Firefox - hardware video decode + DRM
  programs.firefox = {
    enable = true;
    preferences = {
      # Hardware video acceleration (VA-API)
      "media.ffmpeg.vaapi.enabled" = true;
      "media.hardware-video-decoding.force-enabled" = true;
      "gfx.webrender.all" = true;
      # DRM (Widevine) for Netflix, etc.
      "media.eme.enabled" = true;
      "media.gmp-widevinecdm.visible" = true;
      "media.gmp-widevinecdm.enabled" = true;
      # Wayland native
      "widget.use-xdg-desktop-portal.file-picker" = 1;
      "widget.use-xdg-desktop-portal.mime-handler" = 1;
    };
  };

  # Chromium - hardware video decode + Widevine
  programs.chromium = {
    enable = true;
    # Widevine DRM included in NixOS chromium package
    enablePlasmaBrowserIntegration = false;
    # Hardware acceleration and Wayland flags
    extraOpts = {
      # Hardware acceleration
      "HardwareAccelerationModeEnabled" = true;
    };
    defaultSearchProviderEnabled = false;
  };

  # Allow unfree packages (required for NVIDIA drivers, Widevine)
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    nano
    git
    htop
    iotop
    pstree
    lshw
    lsof
    duf
    nload
    openssl
    pciutils
    usbutils
    usbguard
    usbguard-notifier
    wirelesstools
    sshfs
    exfatprogs
    util-linux
    ntfs3g
    dosfstools
    mtools
    bindfs
    v4l-utils
    jq
    fuse3
    mtpfs
    jmtpfs
    cifs-utils
    samba

    # Wayland essentials
    wayland
    xwayland
    wlroots

    # Automounting
    gvfs

    # Polkit agent
    polkit_gnome

    # XFCE helpers
    xfce.exo

    # Notifications
    libnotify

    # NVIDIA tools
    nvtopPackages.full      # GPU monitoring
    mesa-demos         # OpenGL info (glxinfo, glxgears)
    vulkan-tools       # Vulkan info
    clinfo             # OpenCL info

    # Intel tools
    intel-gpu-tools    # intel_gpu_top for iGPU monitoring

    # System76 tools
    system76-firmware
    firmware-manager

    # VPN
    openconnect

    # Thunar thumbnail generators
    ffmpegthumbnailer        # Video thumbnails
    poppler                  # PDF thumbnails
    libgsf                   # ODF/Office document thumbnails
    webp-pixbuf-loader       # WebP image thumbnails
    gnome-epub-thumbnailer   # EPUB thumbnails
    f3d                      # 3D file thumbnails (STL, OBJ, etc.)

    # SSH key management
    keychain                 # Persistent SSH agent across sessions

    # Common Linux tools
    file                     # File type identification
    tree                     # Directory tree view
    ncdu                     # Disk usage analyzer (ncurses)
    bind                     # DNS utilities (dig, nslookup)
    traceroute               # Network path tracing
    mtr                      # Better traceroute with stats
    strace                   # Syscall tracer
    ltrace                   # Library call tracer
    dmidecode                # BIOS/hardware info
    hdparm                   # Disk parameters
    smartmontools            # SMART disk monitoring
    inetutils                # telnet, ftp, hostname, etc.
    ethtool                  # Ethernet settings
    iftop                    # Network bandwidth monitor
    hwinfo                   # Detailed hardware info
    lm_sensors               # Hardware sensors (temp, fan)
    acpi                     # Battery/power info
    psmisc                   # killall, fuser, pstree
    procps                   # ps, top, vmstat, free
    iproute2                 # ip, ss commands
    iputils                  # ping, arping
    parted                   # Partition editor
    bc                       # Calculator
    man-pages                # Linux man pages
    man-pages-posix          # POSIX man pages
  ];

  #####################################################################
  # FIREJAIL
  #####################################################################
  #
  # ═══════════════════════════════════════════════════════════════════
  # FIREJAIL FLAGS REFERENCE
  # ═══════════════════════════════════════════════════════════════════
  #
  # ─── PROFILE CONTROL ───────────────────────────────────────────────
  # --noprofile          : Ignore ALL default profiles, start from scratch
  #                        Use when built-in profile is too restrictive
  # --ignore=OPTION      : Disable specific option from the loaded profile
  #                        e.g. --ignore=private-tmp overrides "private-tmp" in profile
  #
  # ─── FILESYSTEM ISOLATION ──────────────────────────────────────────
  # --whitelist=PATH     : Allow read/write access ONLY to this path
  #                        Everything else in $HOME is hidden/empty
  #                        Creates the dir if it doesn't exist
  # --private-tmp        : Mount empty tmpfs on /tmp (isolates temp files)
  #                        Breaks apps that need shared /tmp (X11, some IPC)
  # --private-dev        : Mount minimal /dev (null, zero, urandom only)
  #                        Blocks GPU (/dev/dri), audio, webcam, USB
  # --noexec=PATH        : Mount PATH with noexec flag (can't run binaries there)
  #                        Profile "noexec" usually applies to /tmp, /home
  #
  # ─── NETWORK ISOLATION ─────────────────────────────────────────────
  # --net=none           : Complete network isolation, no connectivity
  #                        Good for media players, editors, offline tools
  # --net=INTERFACE      : Use only specified network interface
  # --netfilter          : Enable default network filter (blocks most)
  #
  # ─── D-BUS FILTERING ───────────────────────────────────────────────
  # D-Bus = Inter-process communication for Linux desktop
  #
  # --dbus-user=none     : Block ALL user session D-Bus (breaks most GUI apps)
  # --dbus-user=filter   : Allow only explicitly permitted D-Bus services
  # --dbus-user.talk=SVC : Allow app to CALL methods on service SVC
  # --dbus-user.own=SVC  : Allow app to REGISTER as service SVC
  # --dbus-system=filter : Same but for system bus (hardware, power, etc)
  #
  # Common D-Bus services:
  #   org.freedesktop.Notifications  : Desktop notifications (notify-send)
  #   org.freedesktop.portal.*       : XDG portals (file picker, screen share)
  #   org.freedesktop.portal.Desktop : General desktop integration
  #   org.freedesktop.portal.FileChooser : Native file open/save dialogs
  #   org.freedesktop.ScreenSaver    : Inhibit screensaver during video
  #   org.freedesktop.UPower         : Battery status, power events
  #   org.freedesktop.secrets        : Keyring/password storage access
  #   org.gnome.keyring              : GNOME keyring for passwords
  #   org.gnome.SessionManager       : Session state (idle, inhibit)
  #   org.kde.StatusNotifierWatcher  : System tray icons (KDE/Electron apps)
  #
  # ─── CAPABILITY DROPPING ───────────────────────────────────────────
  # Linux capabilities = fine-grained root privileges
  #
  # --caps.drop=all      : Drop ALL capabilities (recommended baseline)
  #                        App runs as unprivileged user, can't:
  #                        - Bind to ports <1024
  #                        - Change file ownership
  #                        - Load kernel modules
  #                        - Use raw sockets
  #                        - Mount filesystems
  # --caps.keep=CAP      : Keep specific capability after dropping all
  #                        e.g. --caps.keep=net_raw for ping
  #
  # ─── PRIVILEGE RESTRICTION ─────────────────────────────────────────
  # --nonewprivs         : Prevent gaining new privileges via setuid/setgid
  #                        Blocks exploits that try to escalate via suid binaries
  #                        Should ALWAYS be enabled
  # --noroot             : Disable root user inside sandbox (even if you're root)
  #                        Maps root UID to nobody, prevents root exploits
  #
  # ─── SYSCALL FILTERING ─────────────────────────────────────────────
  # --seccomp            : Enable seccomp-bpf syscall filter
  #                        Blocks dangerous syscalls (ptrace, mount, etc)
  #                        Can break apps that need unusual syscalls
  #                        (JIT compilers, VMs, GPU drivers sometimes)
  # --seccomp.drop=LIST  : Block specific syscalls
  # --seccomp.keep=LIST  : Only allow specific syscalls (very restrictive)
  #
  # ─── ENVIRONMENT VARIABLES ─────────────────────────────────────────
  # --env=VAR=VALUE      : Set environment variable inside sandbox
  #
  # Common env vars:
  #   GTK_THEME=Adwaita-dark     : Force dark GTK theme
  #   MOZ_ENABLE_WAYLAND=1       : Firefox native Wayland (no XWayland)
  #   MOZ_DRM_DEVICE=/dev/dri/X  : GPU device for Firefox DRM/WebGL
  #   MOZ_DISABLE_RDD_SANDBOX=1  : Disable Firefox RDD sandbox (fixes VA-API)
  #   LIBVA_DRIVER_NAME=iHD      : Intel VA-API driver (hardware video decode)
  #   ELECTRON_OZONE_PLATFORM_HINT=auto : Electron apps auto-detect Wayland
  #
  # ═══════════════════════════════════════════════════════════════════
  #
  programs.firejail = {
    enable = true;
    wrappedBinaries = {

      # ─────────────────────────────────────────────────────────────
      # BROWSERS - Network-exposed, persistent profiles, DRM+HW accel
      # ─────────────────────────────────────────────────────────────

      firefox = {
        executable = "${pkgs.firefox}/bin/firefox";
        profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
        desktop = "${pkgs.firefox}/share/applications/firefox.desktop";
        extraArgs = [
          # Override built-in profile restrictions that break functionality
          "--ignore=private-tmp"    # Firefox needs shared /tmp for IPC
          "--ignore=private-dev"    # Need /dev/dri for GPU acceleration + DRM
          "--ignore=noexec"         # Firefox JIT needs executable memory regions

          # Environment: theme and Wayland/GPU settings
          "--env=GTK_THEME=Adwaita-dark"       # Force dark theme
          "--env=MOZ_ENABLE_WAYLAND=1"         # Native Wayland (no XWayland)
          "--env=MOZ_DRM_DEVICE=/dev/dri/renderD128"  # GPU for DRM content
          "--env=LIBVA_DRIVER_NAME=iHD"        # Intel VA-API driver for HW decode

          # D-Bus: filter mode = only allow what we specify
          "--dbus-user=filter"
          "--dbus-user.talk=org.freedesktop.Notifications"  # Desktop notifications
          "--dbus-user.talk=org.freedesktop.portal.*"       # All XDG portals (file picker, screen share, etc)
          "--dbus-user.talk=org.freedesktop.ScreenSaver"    # Inhibit screensaver during video
          "--dbus-user.talk=org.gnome.SessionManager"       # Session integration
          "--dbus-system=filter"
          "--dbus-system.talk=org.freedesktop.UPower"       # Battery/power status

          # Filesystem: whitelist = ONLY these paths visible from $HOME
          "--whitelist=~/.mozilla"        # Firefox profile (bookmarks, passwords, extensions)
          "--whitelist=~/.cache/mozilla"  # Cache (speeds up browsing)
          "--whitelist=~/Downloads"       # Download location
          "--whitelist=~/Pictures"        # For uploading images

          # Security hardening (baseline for all apps)
          "--caps.drop=all"   # Drop all Linux capabilities
          "--nonewprivs"      # Can't gain privileges via setuid
          "--noroot"          # No root inside sandbox
        ];
      };

      chromium = {
        executable = "${pkgs.chromium}/bin/chromium";
        profile = "${pkgs.firejail}/etc/firejail/chromium.profile";
        desktop = "${pkgs.chromium}/share/applications/chromium-browser.desktop";
        extraArgs = [
          # Override restrictive profile settings
          "--ignore=private-tmp"    # Chromium IPC needs /tmp
          "--ignore=private-dev"    # GPU access for WebGL, video decode, Widevine
          "--ignore=noexec"         # V8 JIT compiler needs exec

          # Environment
          "--env=GTK_THEME=Adwaita-dark"
          "--env=LIBVA_DRIVER_NAME=iHD"  # Intel hardware video decode

          # D-Bus access
          "--dbus-user=filter"
          "--dbus-user.talk=org.freedesktop.Notifications"
          "--dbus-user.talk=org.freedesktop.portal.*"
          "--dbus-user.talk=org.freedesktop.ScreenSaver"
          "--dbus-user.talk=org.kde.StatusNotifierWatcher"  # System tray icon
          "--dbus-system=filter"
          "--dbus-system.talk=org.freedesktop.UPower"

          # Filesystem whitelists
          "--whitelist=~/.config/chromium"   # Profile (bookmarks, extensions, settings)
          "--whitelist=~/.cache/chromium"    # Cache
          "--whitelist=~/.pki"               # SSL certificates database
          "--whitelist=~/Downloads"
          "--whitelist=~/Pictures"

          # Security
          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
        ];
      };

      brave = {
        executable = "${pkgs.brave}/bin/brave";
        profile = "${pkgs.firejail}/etc/firejail/brave.profile";
        desktop = "${pkgs.brave}/share/applications/brave-browser.desktop";
        extraArgs = [
          # Override restrictive profile settings (same as Chromium)
          "--ignore=private-tmp"
          "--ignore=private-dev"
          "--ignore=noexec"

          # Environment
          "--env=GTK_THEME=Adwaita-dark"
          "--env=LIBVA_DRIVER_NAME=iHD"

          # D-Bus access
          "--dbus-user=filter"
          "--dbus-user.talk=org.freedesktop.Notifications"
          "--dbus-user.talk=org.freedesktop.portal.*"
          "--dbus-user.talk=org.freedesktop.ScreenSaver"
          "--dbus-user.talk=org.kde.StatusNotifierWatcher"
          "--dbus-system=filter"
          "--dbus-system.talk=org.freedesktop.UPower"

          # Filesystem whitelists (Brave uses BraveSoftware dir)
          "--whitelist=~/.config/BraveSoftware"
          "--whitelist=~/.cache/BraveSoftware"
          "--whitelist=~/.pki"
          "--whitelist=~/Downloads"
          "--whitelist=~/Pictures"

          # Security
          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # EMAIL - Network-exposed, handles attachments
      # ─────────────────────────────────────────────────────────────
      thunderbird = {
        executable = "${pkgs.thunderbird}/bin/thunderbird";
        profile = "${pkgs.firejail}/etc/firejail/thunderbird.profile";
        desktop = "${pkgs.thunderbird}/share/applications/thunderbird.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"
          "--env=MOZ_ENABLE_WAYLAND=1"         # Native Wayland support

          "--dbus-user.talk=org.freedesktop.Notifications"  # New mail notifications
          "--dbus-user.talk=org.freedesktop.portal.Desktop" # Desktop integration

          "--whitelist=~/Downloads"  # Save attachments

          "--caps.drop=all"   # No special privileges
          "--nonewprivs"      # No privilege escalation
          "--noroot"          # No root in sandbox
          "--seccomp"         # Block dangerous syscalls (TB doesn't need GPU)
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # MESSAGING - Network-exposed
      # ─────────────────────────────────────────────────────────────
      signal-desktop = {
        executable = "${pkgs.signal-desktop}/bin/signal-desktop";
        profile = "${pkgs.firejail}/etc/firejail/signal-desktop.profile";
        desktop = "${signal-desktop-desktopitem}/share/applications/signal-desktop.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"
          "--env=ELECTRON_OZONE_PLATFORM_HINT=auto"  # Auto-detect Wayland for Electron

          "--dbus-user.talk=org.kde.StatusNotifierWatcher"  # System tray icon
          "--dbus-user.talk=org.freedesktop.Notifications"  # Message notifications

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
        ];
      };

      fractal = {
        executable = "${pkgs.fractal}/bin/fractal";
        profile = "${pkgs.firejail}/etc/firejail/fractal.profile";
        desktop = "${pkgs.fractal}/share/applications/org.gnome.Fractal.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          # D-Bus for Matrix client functionality
          "--dbus-user.talk=org.freedesktop.Notifications"     # Message alerts
          "--dbus-user.talk=org.freedesktop.portal.Desktop"    # Desktop integration
          "--dbus-user.talk=org.freedesktop.portal.FileChooser" # Send files
          "--dbus-user.talk=org.freedesktop.secrets"           # Access keyring for E2EE keys
          "--dbus-user.talk=org.gnome.keyring"                 # GNOME keyring

          # Fractal data directories (E2EE keys are critical!)
          "--whitelist=~/.config/fractal"       # Config + encryption keys
          "--whitelist=~/.local/share/fractal"  # Local data
          "--whitelist=~/.cache/fractal"        # Media cache
          "--whitelist=~/Downloads"             # Save files
          "--whitelist=~/Pictures"              # Send images

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--seccomp"       # Syscall filter (GTK app, no JIT needed)
          "--private-tmp"   # Isolated /tmp (no shared X11 needed)
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # OFFICE - Handles untrusted documents (macros, exploits)
      # ─────────────────────────────────────────────────────────────
      libreoffice = {
        executable = "${pkgs.libreoffice}/bin/soffice";
        profile = "${pkgs.firejail}/etc/firejail/libreoffice.profile";
        desktop = "${pkgs.libreoffice}/share/applications/startcenter.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--dbus-user.talk=org.freedesktop.Notifications"  # Save complete, etc

          "--whitelist=~/Documents"   # Primary document location
          "--whitelist=~/Downloads"   # Downloaded docs

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--seccomp"       # Block dangerous syscalls
          "--private-tmp"   # Isolated temp files (defense against macro exploits)
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # MEDIA - Handles untrusted files
      # ─────────────────────────────────────────────────────────────
      vlc = {
        executable = "${pkgs.vlc}/bin/vlc";
        profile = "${pkgs.firejail}/etc/firejail/vlc.profile";
        desktop = "${pkgs.vlc}/share/applications/vlc.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--whitelist=~/Videos"      # Video files
          "--whitelist=~/Music"       # Audio files
          "--whitelist=~/Downloads"   # Downloaded media
          "--whitelist=/media"        # External drives

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--seccomp"       # Syscall filter
          "--net=none"      # NO NETWORK - VLC doesn't need internet for local files
        ];
      };

      handbrake = {
        executable = "${pkgs.handbrake}/bin/ghb";
        profile = "${pkgs.firejail}/etc/firejail/handbrake.profile";
        desktop = "${pkgs.handbrake}/share/applications/fr.handbrake.ghb.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--whitelist=~/Videos"      # Source and output videos
          "--whitelist=~/Downloads"   # Downloaded videos to convert
          "--whitelist=/media"        # External drives

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--net=none"      # Offline transcoding, no network needed
        ];
      };

      audacity = {
        executable = "${pkgs.audacity}/bin/audacity";
        profile = "${pkgs.firejail}/etc/firejail/audacity.profile";
        desktop = "${pkgs.audacity}/share/applications/audacity.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--whitelist=~/Music"       # Audio project files
          "--whitelist=~/Downloads"   # Downloaded audio

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--net=none"      # Audio editing is offline
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # GRAPHICS - Handles untrusted images
      # ─────────────────────────────────────────────────────────────
      gimp = {
        executable = "${pkgs.gimp}/bin/gimp";
        profile = "${pkgs.firejail}/etc/firejail/gimp.profile";
        desktop = "${pkgs.gimp}/share/applications/gimp.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--whitelist=~/Pictures"    # Image files
          "--whitelist=~/Downloads"   # Downloaded images

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--net=none"      # Image editing is offline
        ];
      };

      imv = {
        executable = "${pkgs.imv}/bin/imv";
        profile = "${pkgs.firejail}/etc/firejail/imv.profile";
        extraArgs = [
          # Minimal image viewer - maximum restrictions
          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--net=none"      # Viewing images needs no network
          "--seccomp"       # Block dangerous syscalls
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # DOCUMENTS - Handles untrusted PDFs/ebooks
      # ─────────────────────────────────────────────────────────────
      zathura = {
        executable = "${pkgs.zathura}/bin/zathura";
        profile = "${pkgs.firejail}/etc/firejail/zathura.profile";
        extraArgs = [
          # PDF viewer - very restrictive (PDFs can contain exploits)
          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--net=none"      # PDFs should never need network
          "--seccomp"       # Block dangerous syscalls
          "--private-tmp"   # Isolate temp files
        ];
      };

      calibre = {
        executable = "${pkgs.calibre}/bin/calibre";
        profile = "${pkgs.firejail}/etc/firejail/calibre.profile";
        desktop = "${pkgs.calibre}/share/applications/calibre-gui.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--whitelist=~/Documents"       # Document storage
          "--whitelist=~/Downloads"       # Downloaded ebooks
          "--whitelist=~/Calibre Library" # Calibre's default library location

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--net=none"      # Ebook management is offline
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # 3D PRINTING - Offline tool
      # ─────────────────────────────────────────────────────────────
      orca-slicer = {
        executable = "${pkgs.orca-slicer}/bin/orca-slicer";
        profile = "${pkgs.firejail}/etc/firejail/default.profile";
        desktop = "${pkgs.orca-slicer}/share/applications/OrcaSlicer.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--noprofile"     # Ignore default profile entirely (no good orca profile exists)

          "--whitelist=~/Downloads"              # Downloaded STL files
          "--whitelist=~/3DPrinting"             # 3D printing project folder
          "--whitelist=~/.config/OrcaSlicer"     # App config
          "--whitelist=~/.local/share/OrcaSlicer" # App data

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--net=none"      # Slicing is offline (no cloud printing)
          "--seccomp"       # Syscall filter
        ];
      };

      # ─────────────────────────────────────────────────────────────
      # TORRENTS - Network-exposed
      # ─────────────────────────────────────────────────────────────
      qbittorrent = {
        executable = "${pkgs.qbittorrent-enhanced}/bin/qbittorrent";
        profile = "${pkgs.firejail}/etc/firejail/qbittorrent.profile";
        desktop = "${pkgs.qbittorrent-enhanced}/share/applications/org.qbittorrent.qBittorrent.desktop";
        extraArgs = [
          "--env=GTK_THEME=Adwaita-dark"

          "--whitelist=~/Downloads"  # Torrent download location

          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          # NOTE: No --net=none here - torrents need network!
          # NOTE: No --seccomp - qbittorrent needs some syscalls for DHT/networking
        ];
      };
    };
  };

  #####################################################################
  # Firewall
  #####################################################################
  networking.firewall = {
    enable = true;
    # Port 24800: Barrier/Deskflow KVM sharing (keyboard/mouse across machines)
    # WARNING: KVM traffic is unencrypted. Only use on trusted LANs.
    # For remote use, tunnel through SSH: ssh -L 24800:localhost:24800 host
    allowedTCPPorts = [  ];
    allowedUDPPorts = [  ];
  };

  #####################################################################
  # SSH Server
  #####################################################################
  services.openssh = {
    enable = false;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  #####################################################################
  # SSH Client - Agent & Key Management
  #####################################################################
  programs.ssh = {
    startAgent = true;
    agentTimeout = "4h";  # Keys expire after 4 hours of inactivity
    extraConfig = ''
      AddKeysToAgent yes
      IdentitiesOnly yes
    '';
  };

  system.stateVersion = "25.11";
}

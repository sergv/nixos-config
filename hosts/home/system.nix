{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules =
    #[ "xhci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
    # "sd_mod"
    [
      "nvme"
      "ahci"
      "xhci_pci"
      "usbhid"
      "usb_storage"
    ];
  boot.initrd.kernelModules = [ ];
  # Not clear why kvm-amd was enabled by nixos-generate-config.
  # boot.kernelModules = ["kvm-amd"];
  boot.kernelModules =
    [
      "snd_seq_dummy"
      "snd_hrtimer"
      "snd_seq"
      "snd_seq_device"
      "af_packet"
      "cfg80211"
      "rfkill"
      "8021q"
      "msr"
      "xt_owner"
      "xt_conntrack"
      "nf_conntrack"
      "nf_defrag_ipv6"
      "nf_defrag_ipv4"
      "xt_tcpudp"
      "ipt_rpfilter"
      "xt_pkttype"
      "nft_compat"
      "x_tables"
      "nf_tables"
      "nfnetlink"
      "sch_fq_codel"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
      "nls_iso8859_1"
      "nls_cp437"
      "vfat"
      "fat"
      "nvidia"
      "r8169"
      "onboard_usb_dev"
      "realtek"
      "mdio_devres"
      "of_mdio"
      "fixed_phy"
      "fwnode_mdio"
      "libphy"
      "mdio_bus"
      "snd_hda_codec_alc662"
      "snd_hda_codec_realtek_lib"
      "intel_rapl_msr"
      "snd_hda_codec_generic"
      "spd5118"
      "snd_hda_intel"
      "edac_mce_amd"
      "snd_hda_codec"
      "edac_core"
      "snd_hda_core"
      "joydev"
      "snd_intel_dspcfg"
      "amd_atl"
      "intel_rapl_common"
      "snd_intel_sdw_acpi"
      "input_leds"
      "iosf_mbi"
      "snd_hwdep"
      "mousedev"
      "led_class"
      "polyval_clmulni"
      "rtc_cmos"
      "ghash_clmulni_intel"
      "snd_pcm"
      "aesni_intel"
      "snd_timer"
      "sp5100_tco"
      "rapl"
      "watchdog"
      "snd"
      "soundcore"
      "ccp"
      "tiny_power_button"
      "gpio_amdpt"
      "i2c_piix4"
      "button"
      "amd_3d_vcache"
      "gpio_generic"
      "k10temp"
      "i2c_smbus"
      "evdev"
      "wmi_bmof"
      "vboxnetadp"
      "vboxnetflt"
      "vboxdrv"
      "kvm_amd"
      "drm_ttm_helper"
      "ttm"
      "video"
      "wmi"
      "atkbd"
      "vivaldi_fmap"
      "libps2"
      "serio"
      "fuse"
      "configfs"
      "dmi_sysfs"
      "hid_generic"
      "sd_mod"
      "usbhid"
      "hid"
      "ahci"
      "libahci"
      "libata"
      "nvme"
      "xhci_pci"
      "scsi_mod"
      "xhci_hcd"
      "nvme_core"
      "scsi_common"
      "nvme_keyring"
      "nvme_auth"
      "hkdf"
      "dm_mod"
      "loop"
      "dax"
      "efivarfs"
      "autofs4"
      # Joystick
      "hid_pl"
      "ff_memless"
    ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # For booting see https://nixos.wiki/wiki/Bootloader

  #boot.initrd.kernelModules = ["amdgpu"];

  # Very bad idea to disable this: doing so leads to boot failures
  # complaining about incompatible (lib) device mapper version.
  # boot.initrd.includeDefaultModules = false;

  # For EFI-based systems
  boot.loader.systemd-boot = {
    enable                 = true;
    memtest86.enable       = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.blacklistedKernelModules = [
    # Don’t want my integrated GPU around at all.
    "amdgpu"
    # "dm_mod"
    # Disable HDMI audio which is inferior to speakers
    "snd_hda_codec_hdmi"
    "snd_hda_codec_nvhdmi"
    "kvm.enable_virt_at_load=0"
  ];

  boot.extraModprobeConfig = ''
    # Last resort removal of a module, when other methods of blacklisting failed.
    install snd_hda_codec_hdmi /bin/true
    install snd_hda_codec_nvhdmi /bin/true
  '';

  boot.kernelParams = [
    # Mitigations are compiled away in the kernel so there’s no need
    # to disable them in boot params.
    # "mitigations=off"

    # Disable hyperthreading.
    "nosmt=force" # force turned off, cannot enable later
    # "nosmt" # allow enabling later
    # "preempt=full"

    # Help with PCI problems like
    # ‘nvme nvme0: I/O tag 768 (0300) QID 5 timeout, completion polled’
    #
    # # # General PCI issues, cf https://knightli.com/en/2026/05/24/pci-nomsi-pcie-aspm-off-linux-sata-expansion-card/
    # # # "pci=nomsi"
    #
    # TODO: do in BIOS: switch the SSD mode from RAID to NVME, tweak Intel Volume Management Device (Intel VMD)?
    # May help with
    # cf https://askubuntu.com/questions/1557696/ubuntu-24-04-freezes-with-nvme-nvme0-i-o-timeout-error
    # "pcie_aspm=off"
    # Likely won’t help
    # nvme_core.default_ps_max_latency_us=0
    "pcie_aspm=off"
  ];

  boot.kernel.sysctl = {
    # Allow ‘dmesg’ without root.
    "kernel.dmesg_restrict"      = 0;
    # Allow ‘perf’ without root.
    "kernel.perf_event_paranoid" = -1;
    "kernel.kptr_restrict"       = pkgs.lib.mkForce 0;
  };

  # # More for legacy systems, use the GRUB 2 boot loader.
  # boot.loader.grub = {
  #   enable      = true;
  #   version     = 2;
  #   # Define on which hard drive you want to install Grub.
  #   device      = "/dev/sda";
  #   # Include entries for other OSes.
  #   useOSProber = true;
  #   efiSupport  = true;
  # };

  # New desktop
  fileSystems = {
    # # Vanilla tmpfs root, includes /tmp.
    # "/" = {
    #   device  = "tmpfs";
    #   fsType  = "tmpfs";
    #   options = ["noatime" "nodiratime" "size=8000M" # "mode=1777"
    #             ];
    # };

    # "/nix" = {
    #   depends = [ "/" ];
    #   device = "/dev/disk/by-label/nixos-root";
    #   fsType = "ext4";
    #   options = [
    #     "errors=remount-ro"
    #     "noatime"
    #     "nodiratime"
    #     "lazytime"
    #     "x-gvfs-hide"
    #     "discard"
    #   ];
    # };
    "/boot" = {
      depends = [ "/" ];
      device = "/dev/disk/by-label/NIXOS-BOOT";
      fsType = "vfat";
      options = [
        "nofail"
        "rw"
        "errors=remount-ro"
        "noatime"
        "nodiratime"
        "lazytime"
      ];
    };
    "/nix" = {
      depends = [ "/" ];
      device = "/dev/disk/by-label/nixos-root";
      fsType = "f2fs";
      options = [
        "noatime"
        "nodiratime"
        "lazytime"
        "compress_algorithm=lzo-rle"
        "compress_chksum"
        "atgc"
        "gc_merge"
        "inline_data"
        "inline_dentry"
        "x-gvfs-hide"
      ];
    };

    # sudo mkfs.f2fs -l rootfs -O extra_attr,inode_checksum,sb_checksum,compression
    # "${config.sergv.persistence.permanent-fast-storage}" = {
    #   depends = [ "/" ];
    #   # device = "/dev/disk/by-label/nixos-permanent";
    #   # device = "/dev/disk/by-uuid/18fdd1f5-5975-4fdc-8b6b-8f034644abf1";
    #   fsType = "f2fs";
    #   # options       = ["discard"]; # for ssds
    #   options = [
    #     "noatime"
    #     "nodiratime"
    #     "lazytime"
    #     "compress_algorithm=lzo-rle"
    #     "compress_chksum"
    #     "atgc"
    #     "gc_merge"
    #     "inline_data"
    #     "inline_dentry"
    #     "x-gvfs-hide"
    #   ];
    #   neededForBoot = true;
    # };

    # 4Tb
    "${config.sergv.persistence.permanent-fast-storage}" = {
    # "${config.sergv.persistence.permanent-slow-storage} /permanent/storage-backup" = {
      depends = [ "/" ];
      # device = "/dev/disk/by-label/nixos-permanent";
      device = "/dev/disk/by-uuid/18fdd1f5-5975-4fdc-8b6b-8f034644abf1";
      fsType = "ext4";
      # options       = ["discard"]; # for ssds
      options = [
        "rw"
        "errors=remount-ro"
        "noatime"
        "nodiratime"
        "lazytime"
        "x-gvfs-hide"
      ];
      neededForBoot = true;
    };
    # 8Tb
    "${config.sergv.persistence.permanent-slow-storage}" = {
      depends = [ "/" ];
      device = "/dev/disk/by-uuid/eb1eedc4-1ed2-4716-9839-e3c7823efc82";
      fsType = "ext4";
      # options = ["discard"]; # for ssds
      options = [
        "rw"
        "errors=remount-ro"
        "noatime"
        "nodiratime"
        "lazytime"
        "x-gvfs-hide"
      ];
      neededForBoot = true;
    };
  };

  # Old desktop
  # fileSystems = {
  #   # Includes /tmp
  #   "/" = {
  #     device  = "tmpfs";
  #     fsType  = "tmpfs";
  #     options = ["noatime" "nodiratime" "size=10000M" # "mode=1777"
  #               ];
  #   };
  #   "/nix" = {
  #     device        = "/dev/disk/by-label/NIXOS-ROOT";
  #     fsType        = "ext4";
  #     options       = ["errors=remount-ro" "noatime" "nodiratime" "lazytime"];
  #   };
  #   "/permanent" = {
  #     device        = "/dev/disk/by-label/NIXOS-ROOT";
  #     fsType        = "ext4";
  #     # options       = ["discard"]; # for ssds
  #     options       = ["rw" "errors=remount-ro" "noatime" "nodiratime" "lazytime"];
  #     neededForBoot = true;
  #   };
  #   "/boot" = {
  #     device  = "/dev/disk/by-label/NIXOS-BOOT";
  #     # device  = pkgs.lib.mkForce "/dev/disk/by-label/NIXOS-BOOT";
  #     # device  = "/dev/disk/by-uuid/459be4d4-751d-4032-abef-6faf9545790c";
  #     fsType  = "vfat";
  #     options = ["nofail" "rw" "errors=remount-ro" "noatime" "nodiratime" "lazytime"];
  #   };
  # };

  # environment.etc = {
  #   # Maybe try this if ssh server doesn’t work.
  #   "ssh/ssh_host_rsa_key".source         = "/permanent/etc/ssh/ssh_host_rsa_key";
  #   "ssh/ssh_host_rsa_key.pub".source     = "/permanent/etc/ssh/ssh_host_rsa_key.pub";
  #   "ssh/ssh_host_ed25519_key".source     = "/permanent/etc/ssh/ssh_host_ed25519_key";
  #   "ssh/ssh_host_ed25519_key.pub".source = "/permanent/etc/ssh/ssh_host_ed25519_key.pub";
  # };

  # For running within a VM
  # virtualisation.virtualbox.guest.enable = true;
  virtualisation = {
    docker = {
      # storageDriver = "overlay2";
      rootless = {
        enable            = true;
        setSocketVariable = true;
        daemon.settings   = {
          storage-driver = "overlay2";
        };
      };
    };
    virtualbox.host = {
      enable              = true;
      enableExtensionPack = true;
    };
  };

  # Disable rootless docker at startup - it will start automatically
  # when docker is used.
  systemd.user.services.docker.wantedBy = pkgs.lib.mkForce [ ];

  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable            = true; # Enable PipeWire
    alsa.enable       = true; # Enable ALSA support
    alsa.support32Bit = true; # Enable 32-bit ALSA support
    audio.enable      = true;
    pulse.enable      = true; # Enable PulseAudio compatibility
    # Optional support for JACK applications
    # jack.enable       = true; #

    extraConfig.pipewire = {

      # Allow speakers to go to sleep to conserve power. Unclear whether it works,
      # but speakers seem to be able to suspend now.
      "99-disable-suspend-default" = {
        "stream.properties" = {
          "dither.noise" = 0;
          # rectangular, triangular, triangular-hf, wannamaker3, shaped5
          "dither.method" = "none";
        };
      };

      # # Low-latency setup from https://nixos.wiki/wiki/PipeWire
      # "92-low-latency" = {
      #   "context.properties" = {
      #     "default.clock.rate" = 48000;
      #     "default.clock.quantum" = 32;
      #     "default.clock.min-quantum" = 32;
      #     "default.clock.max-quantum" = 32;
      #   };
      # };
    };

    wireplumber = {
      enable = true;
      extraConfig = {
        "99-enable-suspend-alsa" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  # "node.name" = "~alsa_output.*Speaker";
                  # "node.name" = "~alsa_output.*analog-stereo";
                  "node.name" = "~alsa_output.*";
                }
              ];
              actions = {
                update-props = {
                  "session.suspend-timeout-seconds" = 0;
                  "dither.noise" = 0;
                  # rectangular, triangular, triangular-hf, wannamaker3, shaped5
                  "dither.method" = "none";
                  # "dither.method" = "wannamaker3";
                  # "dither.noise" = 15;
                };
              };
            }
          ];
        };

        "99-disable-hdmi-output" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  # device.name = "alsa_card.pci-0000_01_00.1"
                  "node.name" = "~alsa_output.*hdmi";
                }
              ];
              actions = {
                update-props = {
                  # "device.disabled" = true;
                  "node.disabled" = true;
                };
              };
            }
          ];
        };
      };
    };
  };

  hardware = {
    bluetooth.enable = false;
  };

  # List services that you want to enable:

  networking = {
    # Supreme Commander’s faf client doesn’t work with IPv6 at all.
    enableIPv6 = false;
    hostName   = "home"; # Define your hostname.
    #hostName              = ""; # Use dhcp-provided hostname.
    # networkmanager.enable = true;
    #wireless.enable       = true;  # Enables wireless support via wpa_supplicant.

    # MAC address 	IP address
    # 58:11:22:99:01:e9	192.168.0.11
    # fc:b2:14:6b:a2:aa	192.168.0.12
    # 6c:1f:f7:23:cb:fa	192.168.0.13
    # 04:d6:aa:ca:e5:30	192.168.0.14
    # bc:54:51:38:2e:90	192.168.0.15
    # b0:df:3a:0d:9a:70	192.168.0.16
    extraHosts = ''
      192.168.0.11 home
      192.168.0.12 macbook
      192.168.0.12 macbook-wifi
      192.168.0.13 macbook-wire
      192.168.0.14 smartphone
      192.168.0.15 tablet-10
      192.168.0.16 tablet-8
    '';

    # Prefer eth0 to eno1 and the like.
    usePredictableInterfaceNames = true;

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;

    # # Don’t autoconfigure all network interfaces
    # useDHCP = false;
    # bridges = {
    #   br0 = {
    #     interfaces = ["eth-usb" "eth0"];
    #   };
    # };
    # interfaces.br0 = {
    #   useDHCP = true;
    # };
    interfaces.eth0 = {
      useDHCP = true;
    };

    # Declarative successor of iptables
    # nftables = {
    #   enable = true;
    # };
  };

  nix = {
    settings.system-features = [
      "gccarch-znver3"
      "gccarch-znver4"
    ];
    sshServe = {
      enable  = true;
      keys    =
        [
          (builtins.warn
            ("nix.sshServe ssh key not set in " + __curPos.file)
            "TODO: add public key here")
        ];
      trusted = false;
    };
  };

  powerManagement = {
    enable          = true;
    cpuFreqGovernor = "performance";
  };

  # For Wayland support use https://gitlab.com/chinstrap/gammastep
  services.redshift = {
    enable      = true;
    executable  = "/bin/redshift";
    # executable  = "/bin/redshift-gtk";
    temperature = {
      day   = 5500;
      night = 1900;
    };
  };

  # Enable the X11 windowing system.
  services.xserver = {
    autorun = true; # Start automatically at boot time.
    enable  = true;

    # # So that Xorg's config will be present in /etc
    # exportConfiguration = false;

    xkb = {
      layout  = "us,ru";
      model   = "pc105";
      variant = "dvorak,";
      # terminate:ctrl_alt_bksp
      options = "grp:shifts_toggle,caps:escape";
    };

    # Does not seem to work - replugging device does not make it have
    # qwerty layout.
    config = ''
      Section "InputClass"
        Identifier "Gaming keyboard qwerty layout"
        MatchIsKeyboard "on"
        MatchVendor "SEMICO"
        Option "XkbModel" "pc105"
        Option "XkbLayout" "us"
        Option "XkbOptions" "caps:escape"
        Option "XkbVariant" ""
      EndSection
    '';

    # Touchpad
    # synaptics  = {
    #   enable          = true;
    #   twoFingerScroll = true;
    # };
    # Enable touchpad support.
    # libinput.enable = true;

    #videoDrivers = ["intel" "nvidia"]
    #videoDrivers = ["amdgpu" "nvidia"];
    #videoDrivers = ["modesetting"];

    displayManager = {
      lightdm.enable = true;
    };
  };

  # services.desktopManager = {
  #   xfce                  = {
  #     enable            = true;
  #     enableScreensaver = false;
  #   };
  # };

  # Enable automounting in Thunar
  services.udisks2.enable = true;

  # # For nice graphical effects (presumably in xfce).
  # services.compton = {
  #   enable          = true;
  #   fade            = true;
  #   inactiveOpacity = "0.95";
  #   shadow          = true;
  #   fadeDelta       = 4;
  # };

  services.udev = {
    extraRules = ''
      ## Embedded devices

      SUBSYSTEM=="usb", ATTRS{product}== "Arduino Uno", GROUP="users", MODE="0666"
      SUBSYSTEM=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"

      #SUBSYSTEM="usb", ATTRS{product}== "FT232R USB UART", GROUP="users", MODE="0666"

      ## Ergodox EZ keyboard

      # UDEV Rules for Teensy boards, http://www.pjrc.com/teensy/
      #
      # The latest version of this file may be found at:
      #   http://www.pjrc.com/teensy/49-teensy.rules

      # Teensy rules for the Ergodox EZ Original / Shine / Glow
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

      # STM32 rules for the Planck EZ Standard / Glow
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", \
          MODE:="0666", \
          SYMLINK+="stm32_dfu"

      ## Network adapters

      # Recognize my usb wifi router.
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="a0:f3:c1:1f:1c:30", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="wlan*", NAME="wlan0"

      ## Usb to ethernet adapter.
      #SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:60:6e:43:a4:aa", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth-usb"

      # Lenovo usb to ethernet adapter.
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="00:1a:9f:0c:99:65", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth-usb"
    '';
  };

  services.geoclue2 = {
    enable = pkgs.lib.mkForce false;
  };

  system = {
    nixos.label = "zen4";
  };

  # Disable loading extra kernel modules after boot to avoid security holes.
  security.lockKernelModules = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # # For debugging boot problems
  # boot.initrd.systemd.emergencyAccess = true;
  # systemd.enableEmergencyMode = true;
  # security.lockKernelModules = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

}

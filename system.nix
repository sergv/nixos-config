# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ bore-scheduler-src, kernel-march-patches, linuk-tkg-src }:

{ config, pkgs, ... }:

let nix-daemon-build-dir = "/builds-nix-tmp";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./compressed-root.nix
      (import ./kernel.nix { inherit bore-scheduler-src kernel-march-patches linuk-tkg-src; })
    ];

  # For booting see https://nixos.wiki/wiki/Bootloader

  #boot.initrd.kernelModules = ["amdgpu"];

  # Very bad idea to disable this: doing so leads to boot failures
  # complaining about incompatible (lib) device mapper version.
  # boot.initrd.includeDefaultModules = false;

  # For EFI-based systems
  boot.loader.systemd-boot = {
    enable           = true;
    memtest86.enable = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.blacklistedKernelModules = [
    # Don’t want my integrated GPU around at all.
    "amdgpu"
    # "dm_mod"
  ];

  # boot.kernelParams = [
  #   "mitigations=off"
  #   # "preempt=full"
  # ];

  boot.kernel.sysctl = {
    # Allow ‘perf’ without root.
    "kernel.perf_event_paranoid" = -1;
    "kernel.kptr_restrict"       = pkgs.lib.mkForce 0;
  };

  # # More for legacy systems, use the GRUB 2 boot loader.
  # boot.loader.grub = {
  #   enable  = true;
  #   version = 2;
  #   # Define on which hard drive you want to install Grub.
  #   device  = "/dev/sda";
  #   # Include entries for other OSes.
  #   useOSProber = true;
  #   efiSupport = true;
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

    "/nix" = {
      depends       = ["/"];
      device        = "/dev/disk/by-label/nixos-root";
      fsType        = "ext4";
      options       = ["errors=remount-ro" "noatime" "nodiratime" "lazytime" "x-gvfs-hide" "discard"];
    };
    "/permanent" = {
      depends       = ["/"];
      device        = "/dev/disk/by-label/nixos-permanent";
      fsType        = "ext4";
      # options       = ["discard"]; # for ssds
      options       = ["rw" "errors=remount-ro" "noatime" "nodiratime" "lazytime" "x-gvfs-hide"];
      neededForBoot = true;
    };
    "/boot" = {
      depends = ["/"];
      device  = "/dev/disk/by-label/NIXOS-BOOT";
      fsType  = "vfat";
      options = ["nofail" "rw" "errors=remount-ro" "noatime" "nodiratime" "lazytime"];
    };
    "/permanent/storage" = {
      depends   = ["/"];
      device    = "/dev/disk/by-uuid/eb1eedc4-1ed2-4716-9839-e3c7823efc82";
      fsType    = "ext4";
      # options = ["discard"]; # for ssds
      options   = ["rw" "errors=remount-ro" "noatime" "nodiratime" "lazytime" "x-gvfs-hide"];
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

  # Will activate home-manager profiles for each user upon login
  # This is useful when using ephemeral installations
  environment.loginShellInit = ''
    [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
  '';

  # environment.etc = {
  #   # Maybe try this if ssh server doesn’t work.
  #   "ssh/ssh_host_rsa_key".source         = "/permanent/etc/ssh/ssh_host_rsa_key";
  #   "ssh/ssh_host_rsa_key.pub".source     = "/permanent/etc/ssh/ssh_host_rsa_key.pub";
  #   "ssh/ssh_host_ed25519_key".source     = "/permanent/etc/ssh/ssh_host_ed25519_key";
  #   "ssh/ssh_host_ed25519_key.pub".source = "/permanent/etc/ssh/ssh_host_ed25519_key.pub";
  # };

  environment.persistence."/permanent" = {
    hideMounts = true;

    directories = [
      "/etc/NetworkManager/system-connections"
      "/var/lib"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };

  programs.adb.enable = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = [
      pkgs.alsa-tools
      pkgs.alsa-utils
      pkgs.killall
      # pkgs.libnotify # for showing notifications in wm_operate.py
      # pkgs.libreoffice
      pkgs.perf
      pkgs.ltrace
      pkgs.man
      pkgs.man-pages
      pkgs.mkpasswd
      pkgs.pciutils
      pkgs.sudo
      pkgs.strace
      pkgs.vim
      # pkgs.veracrypt
      #(pkgs.wineFull.override { netapiSupport = false; })

      # pkgs.bumblebee
      # pkgs.jdk7
      # pkgs.jdk
      # pkgs.ocaml
      # pkgs.octaveFull
      # pkgs.python36Packages.ipython
      # pkgs.python36Packages.jupyter
      # pkgs.python36Packages.jupyter_client
      # pkgs.python36Packages.matplotlib
      # pkgs.python36Packages.sympy

      #nix-bash-completions

      # # For Xfce
      # pkgs.networkmanagerapplet
    ];
  };

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

  services.pulseaudio = {
    enable       = true;
    support32Bit = true;
  };

  hardware = {
    bluetooth.enable  = false;

    # OpenGL
    graphics.enable = true;

    # Enable acceleration in x32 wine apps.
    graphics.enable32Bit = true;

    nvidia = {
      modesetting.enable = false;

	    # Enable power management (do not disable this unless you have a reason to).
	    # Likely to cause problems on laptops and with screen tearing if disabled.
	    powerManagement.enable = true;

      # Use the open source version of the kernel module ("nouveau")
	    # Note that this offers much lower performance and does not
	    # support all the latest Nvidia GPU features.
	    # You most likely don't want this.
      # Only available on driver 515.43.04+
      open = false;

      prime.offload.enable = false;

      # Enable the Nvidia settings menu,
	    # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  console = {
    font   = "Lat2-Terminus16";
    keyMap = "dvorak";
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };

  # List services that you want to enable:

  networking = {
    # Supreme Commander’s faf cilent doesn’t work with IPv6 at all.
    enableIPv6 = false;
    hostName   = "home"; # Define your hostname.
    #hostName              = ""; # Use dhcp-provided hostname.
    # networkmanager.enable = true;
    #wireless.enable       = true;  # Enables wireless support via wpa_supplicant.

    # Prefer eth0 to eno1 and the like.
    usePredictableInterfaceNames = true;

    # Don’t autoconfigure all network interfaces
    useDHCP = false;
    bridges = {
      br0 = {
        interfaces = ["eth-usb" "eth0"];
      };
    };
    interfaces.br0 = {
      useDHCP = true;
    };
    #interfaces.eth0 = {
    #  useDHCP = true;
    #};

    firewall = {
      enable = true;
      allowPing = false;
      extraCommands =
        ''
          iptables -I OUTPUT 1 -m owner --gid-owner no-internet -j DROP
        '';

      allowedTCPPorts = [
        # For i2p:
        7656 # default sam port
        7070 # default web interface port
        4447 # default socks proxy port
        4444 # default http proxy port
      ];

      # Open ports in the firewall.
      # allowedTCPPorts = [... ];
      # allowedUDPPorts = [... ];
    };

    # Declarative successor of iptables
    # nftables = {
    #   enable = true;
    # };
  };

  # Enable commands like ‘nix search’ and flakes.
  nix = {
    gc.automatic = false;
    package      = pkgs.unstable.nixVersions.stable;
    settings     = {
      allowed-users         = ["@wheel" "nix-ssh"];
      bash-prompt-prefix    = "[nix] ";
      experimental-features = ["nix-command" "flakes"];
      # accept-flake-config   = true;
      # More at https://nixos.org/nix/manual/#conf-system-features.
      system-features       = ["big-parallel" "gccarch-znver3" "gccarch-znver4"];
      build-dir             = nix-daemon-build-dir;
    };
    # extraOptions = pkgs.lib.optionalString (config.nix.package == pkgs.nixVersions.stable)
    #   "experimental-features = nix-command flakes";

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    sshServe = {
      enable  = true;
      keys    = [ "TODO: add public key here" ];
      trusted = false;
    };
  };

  programs.bash.completion.enable = true;

  # Needed to make impermanence's allow_other work.
  programs.fuse.userAllowOther = true;

  # To be able to manipulate gtk settings.
  programs.dconf.enable = true;

  # Recommendations for secure secure shell, https://stribika.github.io/2015/01/04/secure-secure-shell.html
  programs.ssh = {
    ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
      "aes256-ctr"
      "aes192-ctr"
      "aes128-ctr"
    ];
    hostKeyAlgorithms = ["ssh-ed25519" "ssh-rsa"];
    kexAlgorithms = [
      "curve25519-sha256@libssh.org"
      "diffie-hellman-group-exchange-sha256"
    ];
    macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
      "hmac-sha2-512"
      "hmac-sha2-256"
    ];
    pubkeyAcceptedKeyTypes = ["ssh-ed25519" "ssh-rsa"];
  };

  security.sudo = {
    enable             = true;
    execWheelOnly      = true;
    wheelNeedsPassword = true;
    extraRules         = [
      {
        users = ["sergey"];
        commands = [
          { command = "ALL";
            options = ["SETENV" "NOPASSWD"];
          }
        ];
      }
    ];
  };

  services.acpid.enable = true;
  powerManagement = {
    enable          = true;
    cpuFreqGovernor = "performance";
  };

  services.locate = {
    enable    = true;
    package   = pkgs.mlocate;
    interval  = "daily";
  };

  services.pipewire = {
    enable = false;
  };

  # Enable CUPS to print documents.
  services.printing.enable = false;

  location = {
    # London
    latitude  = 51.508530;
    longitude = -0.076132;
    # Kiev
    # latitude    = "50.45";
    # longitude   = "30.5233";
  };

  # For Wayland support use https://gitlab.com/chinstrap/gammastep
  services.redshift = {
    enable    = true;
    executable = "/bin/redshift";
    # executable = "/bin/redshift-gtk";
    temperature = {
      day   = 5500;
      night = 1900;
    };
  };

  # Enable the X11 windowing system.
  services.xserver = {
    autorun    = true; # Start automatically at boot time.
    enable     = true;

    # # So that Xorg's config will be present in /etc
    # exportConfiguration = false;

    xkb = {
      layout  = "us,ru";
      model   = "pc105";
      variant = "dvorak,";
      # terminate:ctrl_alt_bksp
      options = "grp:shifts_toggle,caps:escape";
    };

    # Touchpad
    # synaptics  = {
    #   enable          = true;
    #   twoFingerScroll = true;
    # };
    # Enable touchpad support.
    # libinput.enable = true;

    #videoDrivers = ["intel" "nvidia"]
    #videoDrivers = ["amdgpu" "nvidia"];
    videoDrivers = ["nvidia"];
    #videoDrivers = ["modesetting"];

    #KDE
    #displayManager.sddm.enable = false;

    displayManager = {
      lightdm.enable = true;
    };

  };

  # services.displayManager.defaultSession = "plasma";
  services.displayManager.defaultSession = "plasmax11";
  # services.displayManager.defaultSession = "plasma";

  services.desktopManager = {
    # plasma5 = {
    #   enable        = true;
    # };
    plasma6 = {
      enable        = true;
    };
    # xfce                  = {
    #   enable            = true;
    #   enableScreensaver = false;
    # };
  };

  # Seems to have no effect on Plasma 6, thus Plasma 5 only.
  environment.etc."xdg/kwinrc".text = pkgs.lib.generators.toINI {} {
    # Disable Application Launcher menu when Win-key is pressed, https://askubuntu.com/questions/1256305/how-do-i-prevent-application-launcher-pop-up-when-win-key-is-pressed-in-kde.
    "ModifierOnlyShortcuts" = {
      Meta = "";
    };
  };

  environment.plasma6.excludePackages = [
    pkgs.kdePackages.kpeople
    pkgs.kdePackages.kwallet
    pkgs.kdePackages.kwallet-pam
    pkgs.kdePackages.kwalletmanager
    pkgs.kdePackages.milou
  ];

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
    extraRules =
      ''
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

  systemd = {
    services.nix-daemon.environment.TMPDIR = nix-daemon-build-dir;

    tmpfiles.rules = [
      "d ${nix-daemon-build-dir} 0755 root root 7d -"
      # Never clear /tmp directory
      "q /tmp     1777 root root - -"
      # Clear /var/tmp whenever as it was by default.
      "q /var/tmp 1777 root root - 30d"
    ];

    settings.Manager = {
      # File limit.
      DefaultLimitNOFILE = "8192:10485760";
      # Timeout is for starting jobs that hang for any reason.
      DefaultTimeoutStopSec = "10s";
    };
    user.extraConfig =
    ''
      DefaultLimitNOFILE=8192:262144
    '';
  };

  # Set your time zone.
  time.timeZone = "Europe/London";

  users = {
    # Make sure that users are managed only through configuration.nix
    mutableUsers = false;
    groups = {
      no-internet = {};
    };
    users = {
    #};
    ## Define a user account. Don't forget to set a password with ‘passwd’.
    #extraUsers = {
      root = {
        hashedPassword = "Yeah, like I'm going to tell you even my password hash";
      };
      sergey = {
        extraGroups = [
          "adm"
          "adbusers"
          "audio"
          "netdev"
          "networkmanager"
          # Doesn’t disable internet per se, but I need to be part of the group
          # to be able to run ‘no-internet’ script.
          "no-internet"
          "plugdev"
          "sudo"
          "vboxusers"
          "video"
          "wheel"
        ];
        description                 = "sergey"; # "Sergey Vinokurov";
        isNormalUser                = true;
        uid                         = 1000;
        shell                       = pkgs.bash;
        # mkpasswd -m sha-512       <password>
        hashedPassword              = "Yeah, like I'm going to tell you even my password hash";
        openssh.authorizedKeys.keys = [
          "Yeah, like I'm going to tell you even my public key. You'll need to WORK for it."
        ];
      };
    };
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable      = true;
    extraConfig = "PubkeyAcceptedKeyTypes = ssh-rsa,ssh-ed25519";
    settings    = {
      PermitRootLogin        = "no";
      PasswordAuthentication = false;
      X11Forwarding          = true;
    };
  };

  services.i2p = {
    enable  = true;
  };

  # services.i2pd = {
  #   enable  = true;
  #   address = "127.0.0.1"; # you may want to set this to 0.0.0.0 if you are planning to use an ssh tunnel
  #   proto   = {
  #     http.enable       = true;
  #     socksProxy.enable = true;
  #     httpProxy.enable  = true;
  #   };
  # };

  services.tor = {
    enable        = true;
    client.enable = true;

    # Disable GeoIP to prevent the Tor client from estimating the locations of Tor nodes it connects to
    enableGeoIP = false;

    # Enable and configure the Tor relay
    relay = {
      enable = false;
      role = "relay";  # Set the relay role (e.g., "relay", "bridge")
    };

    # Configure Tor settings
    settings = {
      Nickname = "WeAreLegion";
      ContactInfo = "legion@legion.com";

      # Bandwidth settings
      MaxAdvertisedBandwidth = "6 MB";
      BandWidthRate = "5 MB";
      RelayBandwidthRate = "5 MB";
      RelayBandwidthBurst = "6 MB";

      # # Restrict exit nodes to a specific country (use the appropriate country code)
      # ExitNodes = "{ch} StrictNodes 1";

      # Reject all exit traffic
      ExitPolicy = ["reject *:*"];

      # Performance and security settings
      CookieAuthentication = true;
      AvoidDiskWrites      = 1;
      HardwareAccel        = 1;
      SafeLogging          = 1;
      NumCPUs              = 2;

      # Network settings
      ORPort      = [443 9001];
      Dirport     = 9002;

      ControlPort = 9051;
    };
  };

  zramSwap = {
    enable        = true;
    algorithm     = "zstd";
    memoryPercent = 33;
  };

  system = {
    nixos.label = "zen4";
    autoUpgrade = { enable = false; allowReboot = false; };

    # Include everything required to build every package on the system.
    # includeBuildDependencies = true;
  };

  fonts.fontconfig = {
    enable        = true;
    hinting.style = "full";
    antialias     = true;
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
}

# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let nix-daemon-build-dir = "/tmp/nix-daemon";
in
{
  imports =
    [# Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./compressed-root.nix
      ./kernel.nix
    ];

  # For booting see https://nixos.wiki/wiki/Bootloader

  #boot.initrd.kernelModules = ["amdgpu"];

  # For EFI-based systems
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.kernelParams = [
    "mitigations=off"
    "preempt=full"
  ];

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
    users.sergey = {
      directories = [
        "art"
        "bicycle"
        "books"
        "documents"
        "Documents"
        "Downloads"
        "dwhelper"
        "films"
        "games"
        "health"
        "home" # remove?
        "Katya"
        "migration" # remove?
        "Music"
        "nix"
        "Pictures"
        { directory = "projects"; mode = "0700"; }
        "recipes"
        "relocation"
        "scripts"
        "sites"
        "software"
        "Telegram"
        "tmp"
        "torrents"
        "travelling"
        "Videos"
        "vim"
        "VirtualBox VMs"

        { directory = ".cabal"; mode = "0700"; }
        { directory = ".cargo"; mode = "0700"; }
        { directory = ".gradle"; mode = "0700"; }
        { directory = ".isabelle"; mode = "0700"; }
        { directory = ".stack"; mode = "0700"; }

        { directory = ".bitcoin"; mode = "0700"; }
        { directory = ".electrum"; mode = "0700"; }
        { directory = ".dosbox"; mode = "0700"; }
        { directory = ".emacs.d"; mode = "0700"; }
        { directory = ".ghc"; mode = "0700"; }
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".litecoin"; mode = "0700"; }
        { directory = ".mozilla"; mode = "0700"; }
        { directory = ".paradoxlauncher"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        { directory = ".thunderbird"; mode = "0700"; }

        ".config/android"
        ".config/AndroidStudio3.2"
        ".config/.arduino15"
        ".config/audacious"
        # ".config/autostart"
        ".config/bitcoin"
        ".config/chromium"
        ".config/dconf"
        ".config/fontforge"
        ".config/Google"
        ".config/htop"
        ".config/keybase"
        ".config/libreoffice"
        ".config/mc"
        ".config/paradox-launcher-v2"
        ".config/pulse"
        ".config/ristretto"
        ".config/transmission"
        ".config/vlc"
        ".config/xfce4"
        ".config/VirtualBox"
        ".config/Xilinx"

        ".local/share/direnv"
        ".local/share/docker"
        ".local/share/3909"
        ".local/share/Anki"
        ".local/share/Anki2"
        ".local/share/aspyr-media"
        { directory = ".local/share/keyrings"; mode = "0700"; }
        ".local/share/mc"
        ".local/share/mime"
        ".local/share/openmw"
        ".local/share/Paradox Interactive"
        ".local/share/ristretto"
        ".local/share/TelegramDesktop"
        ".local/share/trash"
        ".local/share/vlc"

        # KDE
        ".config/gtk-3.0" # fuse mounted to /home/$USERNAME/.config/gtk-3.0
        ".config/gtk-4.0"
        ".config/KDE"
        ".config/kde.org"
        ".config/kdedefaults"
        ".config/plasma-workspace"
        ".config/xsettingsd"
        ".kde"

        ".local/share/RecentDocuments"
        ".local/share/baloo"
        ".local/share/dolphin"
        ".local/share/feral-interactive"
        ".local/share/gwenview"
        ".local/share/kactivitymanagerd"
        ".local/share/kate"
        ".local/share/kcookiejar"
        ".local/share/kded5"
        ".local/share/klipper"
        ".local/share/konsole"
        ".local/share/kscreen"
        ".local/share/ksysguard"
        ".local/share/kwalletd"
        ".local/share/kxmlgui5"
        ".local/share/okular"
        ".local/share/plasma_icons"
        ".local/share/plasma_notes"
        ".local/share/plasma-systemmonitor"
        ".local/share/sddm"
      ];
    };
  };

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = [
      pkgs.alsaTools
      pkgs.alsaUtils
      # pkgs.android-studio
      # pkgs.androidsdk
      # pkgs.androidndk
      pkgs.android-udev-rules
      # pkgs.bumblebee
      # pkgs.jdk7
      # pkgs.jdk
      pkgs.killall
      # pkgs.libnotify # for showing notifications in wm_operate.py
      # pkgs.libreoffice
      pkgs.linuxPackages.perf
      pkgs.ltrace
      pkgs.man
      pkgs.man-pages
      pkgs.mkpasswd
      # pkgs.ocaml
      # pkgs.octaveFull
      pkgs.pciutils
      pkgs.plasma-systemmonitor
      # pkgs.python36Packages.ipython
      # pkgs.python36Packages.jupyter
      # pkgs.python36Packages.jupyter_client
      # pkgs.python36Packages.matplotlib
      # pkgs.python36Packages.sympy
      pkgs.sudo
      pkgs.strace
      pkgs.vim
      # pkgs.veracrypt
      #(pkgs.wineFull.override { netapiSupport = false; })
      #pkgs.winetricks

      #gvenview
      #okular
      #evince
      #htop
      #kde system monitor
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
    }; #.enable = true;
    virtualbox.host = {
      enable              = true;
      enableExtensionPack = true;
    };
  };

  hardware = {
    bluetooth.enable  = false;
    pulseaudio = {
      enable       = true;
      support32Bit = true;
    };

    opengl = {
      enable          = true;
      driSupport      = true;
      # Enable acceleration in x32 wine apps.
      driSupport32Bit = true;
    };

    nvidia = {
      # Modesetting is needed most of the time
      modesetting.enable = true;

	    # Enable power management (do not disable this unless you have a reason to).
	    # Likely to cause problems on laptops and with screen tearing if disabled.
	    powerManagement.enable = true;

      # Use the open source version of the kernel module ("nouveau")
	    # Note that this offers much lower performance and does not
	    # support all the latest Nvidia GPU features.
	    # You most likely don't want this.
      # Only available on driver 515.43.04+
      open = false;

      # Enable the Nvidia settings menu,
	    # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  sound.enable = true;

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
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [... ];
  # networking.firewall.allowedUDPPorts = [... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable commands like ‘nix search’ and flakes.
  nix = {
    gc.automatic = false;
    package      = pkgs.unstable.nixFlakes;
    settings     = {
      allowed-users         = ["@wheel"];
      bash-prompt-prefix    = "[nix] ";
      experimental-features = ["nix-command" "flakes"];
      # More at https://nixos.org/nix/manual/#conf-system-features.
      system-features       = ["big-parallel" "gccarch-znver3" "gccarch-znver4"];
    };
    # extraOptions = pkgs.lib.optionalString (config.nix.package == pkgs.nixFlakes)
    #   "experimental-features = nix-command flakes";
  };

  programs.bash.enableCompletion = true;

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

  security.pam = {
    loginLimits = [
      {
        domain = "*";
        type   = "soft";
        item   = "nofile";
        value  = "8192";
      }
      {
        domain = "*";
        type   = "hard";
        item   = "nofile";
        value  = "1048576";
      }
      # {
      #   domain = "@users";
      #   type   = "hard";
      #   item   = "data";
      #   value  = "7000000"; # kill process if it goes over 7Gb
      # }
      # {
      #   domain = "@users";
      #   type   = "soft";
      #   item   = "data";
      #   value  = "4000000"; # Notify process if it eats more than 4Gb
      # }
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
    # Silence warning.
    localuser = null;
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

    desktopManager = {
      plasma5 = {
        phononBackend = "vlc";
        enable        = true;
      };
      # xfce                  = {
      #   enable            = true;
      #   enableScreensaver = false;
      # };
    };
    displayManager = {
      defaultSession = "plasma";
      lightdm.enable = true;
    };
  };

  environment.etc."xdg/kwinrc".text = pkgs.lib.generators.toINI {} {
    # Disable Application Launcher menu when Win-key is pressed, https://askubuntu.com/questions/1256305/how-do-i-prevent-application-launcher-pop-up-when-win-key-is-pressed-in-kde.
    "ModifierOnlyShortcuts" = {
      Meta = "";
    };
  };

  environment.plasma5.excludePackages = [
    pkgs.plasma5Packages.kpeople
    pkgs.plasma5Packages.kwallet
    pkgs.plasma5Packages.kwallet-pam
    pkgs.plasma5Packages.kwalletmanager
    pkgs.plasma5Packages.milou
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
      "d ${nix-daemon-build-dir} - root nixbld 7d -"
    ];

    # File limit is for better for steam proton games.
    # Timeout is for starting jobs that hang for any reason.
    extraConfig = ''
      DefaultLimitNOFILE=10485760
      DefaultTimeoutStopSec=10s
    '';
  };

  # Set your time zone.
  time.timeZone = "Europe/London";

  users = {
    # Make sure that users are managed only through configuration.nix
    mutableUsers = false;
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
          "audio"
          "netdev"
          "networkmanager"
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

  services.tor = {
    enable        = true;
    client.enable = true;
    settings      = {
      ControlPort = 9051;
    };
  };

  zramSwap = {
    enable        = true;
    algorithm     = "zstd";
    memoryPercent = 33;
  };

  system.nixos.label = "arch-generic";

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

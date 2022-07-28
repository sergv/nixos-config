# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # For booting see https://nixos.wiki/wiki/Bootloader

  # For EFI-based systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";

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

  fileSystems = {
    # Includes /tmp
    "/" = {
      fsType  = "tmpfs";
      options = [ "noatime" "nodiratime" "size=10000M" "mode=1777" ];
    };
    "/permanent" = {
      device        = "/dev/disk/by-label/NIXOS-ROOT";
      # device        = pkgs.lib.mkForce "/dev/disk/by-label/NIXOS-ROOT";
      fsType        = "ext4";
      # options       = [ "discard" ]; # for ssds
      options       = [ "rw" "errors=remount-ro" "noatime" "nodiratime" "lazytime" ];
      neededForBoot = true;
    };
    "/boot" = {
      device  = "/dev/disk/by-label/nixos-boot";
      fsType  = "vfat";
      options = [ "nofail" "rw" "errors=remount-ro" "noatime" "nodiratime" "lazytime" ];
    };
  };

  environment.etc = {
    # Maybe try this if ssh server doesn’t work.
    "ssh/ssh_host_rsa_key".source         = "/persistence/etc/ssh/ssh_host_rsa_key";
    "ssh/ssh_host_rsa_key.pub".source     = "/persistence/etc/ssh/ssh_host_rsa_key.pub";
    "ssh/ssh_host_ed25519_key".source     = "/persistence/etc/ssh/ssh_host_ed25519_key";
    "ssh/ssh_host_ed25519_key.pub".source = "/persistence/etc/ssh/ssh_host_ed25519_key.pub";
  };

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
        { directory = ".gradle"; mode = "0700"; }
        { directory = ".isabelle"; mode = "0700"; }
        { directory = ".stack"; mode = "0700"; }

        { directory = ".bitcoin"; mode = "0700"; }
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
        ".config/fontforce"
        ".config/Google"
        ".config/keybase"
        ".config/libreoffice"
        ".config/mc"
        ".config/paradox-launcher-v2"
        ".config/pulse"
        ".config/ristretto"
        ".config/Sandbox Interactive GmbH"
        ".config/transmission"
        ".config/vlc"
        ".config/xfce4"
        ".config/Xilinx"

        ".local/share/direnv"
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
        ".config/gtk-3.0"   # fuse mounted to /home/$USERNAME/.config/gtk-3.0
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
      files = [
        ".emacs"
        "machine-specific-setup"

        "github-recovery-codes.txt"
        "mars.exe"
        "password.org"
        "todo.org"
        ".rtorrent.rc"
        ".viminfo"
        ".vimrc"

        "O0DGDxpMBNs.jpg"

        ".config/Audaciousrc"
        ".config/QtProject.conf"

        ".local/ghci.conf"
        ".local/share/recently-used.xbel"

        # KDE
        ".config/akregatorrc"
        ".config/baloofileinformationrc"
        ".config/baloofilerc"
        ".config/bluedevilglobalrc"
        ".config/device_automounter_kcmrc"
        ".config/dolphinrc"
        ".config/filetypesrc"
        ".config/gtkrc"
        ".config/gtkrc-2.0"
        ".config/gwenviewrc"
        ".config/kaccessrc-pluginsrc"
        ".config/kactivitymanagerd-pluginsrc"
        ".config/kactivitymanagerd-statsrc"
        ".config/kactivitymanagerd-switcher"
        ".config/kactivitymanagerdrc"
        ".config/katemetainfos"
        ".config/katerc"
        ".config/kateschemarc"
        ".config/katevirc"
        ".config/kcmfonts"
        ".config/kcminputrc"
        ".config/kconf_updaterc"
        ".config/kded5rc"
        ".config/kded_device_automounterrc"
        ".config/kdeglobals"
        ".config/kgammarc"
        ".config/kglobalshortcutsrc"
        ".config/kfontinstuirc"
        ".config/khotkeysrc"
        ".config/kiorc"
        ".config/kmenueditrc"
        ".config/kmixrc"
        ".config/konsolerc"
        ".config/konsolesshconfig"
        ".config/krunnerrc"
        ".config/kscreenlockerrc"
        ".config/kservicemenurc"
        ".config/ksmserverrc"
        ".config/ksplashrc"
        ".config/ktimezonedrc"
        ".config/kuriikwsfilterrc"
        ".config/kwalletrc"
        ".config/kwinrc"
        ".config/kwinrulesrc"
        ".config/kxkbrc"
        ".config/mimeapps.list"
        ".config/okularpartrc"
        ".config/okularrc"
        ".config/partitionmanagerrc"
        ".config/plasma-localerc"
        ".config/plasma-nm"
        ".config/plasma-org.kde.plasma.desktop-appletsrc"
        ".config/plasmanotifyrc"
        ".config/plasmarc"
        ".config/plasmashellrc"
        ".config/PlasmaUserFeedback"
        ".config/plasmawindowed-appletsrc"
        ".config/plasmawindowedrc"
        ".config/powerdevilrc"
        ".config/powermanagementprofilesrc"
        ".config/spectaclerc"
        ".config/startkderc"
        ".config/systemsettingsrc"
        ".config/Trolltech.conf"
        ".config/user-dirs.dirs"
        ".config/user-dirs.locale"

        ".local/share/krunnerstaterc"
        ".local/share/user-places.xbel"
        ".local/share/user-places.xbel.bak"
        ".local/share/user-places.xbel.tbcache"
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
      pkgs.redshift
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

  nixpkgs.config = {
    allowUnfree = true; # For nvidia drivers.
    # allowBroken = true;
  };

  # For running within a VM
  # virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.host = {
    enable              = true;
    enableExtensionPack = true;
  };

  hardware = {
    bluetooth.enable  = false;
    pulseaudio.enable = true;

    opengl = {
      enable          = true;
      driSupport      = true;
      # Enable acceleration in x32 wine apps.
      driSupport32Bit = true;
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

  # Enable the OpenSSH daemon.
  services.openssh.enable = false;

  networking = {
    hostName = "home"; # Define your hostname.
    #hostName              = ""; # Use dhcp-provided hostname.
    # networkmanager.enable = true;
    #wireless.enable       = true;  # Enables wireless support via wpa_supplicant.

    # Don’t autoconfigure all network interfaces
    useDHCP = false;
    bridges = {
      br0 = {
        interfaces = [ "eth-usb" "enp4s0" ];
      };
    };
    interfaces.br0 = {
      useDHCP = true;
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable commands like ‘nix search’ and flakes.
  nix = {
    allowedUsers = [ "@wheel" ];
    gc.automatic = false;
    package      = pkgs.nixFlakes;
    settings     = {
      experimental-features = [ "nix-command" "flakes" ];
    };
    # extraOptions = pkgs.lib.optionalString (config.nix.package == pkgs.nixFlakes)
    #   "experimental-features = nix-command flakes";
  };

  programs.bash.enableCompletion = true;

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
    hostKeyAlgorithms = [ "ssh-ed25519" "ssh-rsa" ];
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
    pubkeyAcceptedKeyTypes = [ "ssh-ed25519" "ssh-rsa" ];
  };

  security.sudo = {
    enable             = true;
    execWheelOnly      = true;
    wheelNeedsPassword = true;
    extraRules         = [
      {
        users = [ "sergey" ];
        commands = [
          { command = "ALL";
            options = [ "SETENV" "NOPASSWD" ];
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
    # executable = "/bin/redshift";
    executable = "/bin/redshift-gtk";
    temperature = {
      day   = 5500;
      night = 1900;
    };
  };

  # Enable the X11 windowing system.
  services.xserver = {
    autorun    = true; # Start automatically at boot time.
    enable     = true;

    layout     = "us,ru";
    xkbModel   = "pc105";
    xkbVariant = "dvorak,";
    xkbOptions = "terminate:ctrl_alt_bksp,grp:shifts_toggle,caps:escape";

    # Touchpad
    # synaptics  = {
    #   enable          = true;
    #   twoFingerScroll = true;
    # };

    #videoDrivers = [ "intel" "nvidia" ]
    videoDrivers = [ "nvidia" ];

    #KDE
    #displayManager.sddm.enable    = false;
    #desktopManager.plasma5.enable = false;

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

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

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

  # Better for steam proton games.
  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

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
        description    = "Sergey Vinokurov";
        isNormalUser   = true;
        uid            = 1000;
        shell          = pkgs.bash;
        # mkpasswd -m sha-512 <password>
        hashedPassword = "Yeah, like I'm going to tell you even my password hash";
      };
    };
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

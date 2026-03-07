# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{}:

{ config, pkgs, ... }:

let nix-daemon-build-dir = "/builds-nix-tmp";

    # TODO: add certificate file and reference it here
    certificateFile = null;
in
{

  wsl = {
    enable                             = true;
    defaultUser                        = "sergey";
    wslConf.network.generateResolvConf = false;
  };

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
    hostName   = "nixos"; # Define your hostname.
    #hostName              = ""; # Use dhcp-provided hostname.
    networkmanager.enable = true;
    # wireless.enable       = true;  # Enables wireless support via wpa_supplicant.

    # Prefer eth0 to eno1 and the like.
    usePredictableInterfaceNames = true;

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

    # interfaces.eth0 = {
    #  useDHCP = true;
    # };

    nameservers = [
      # Todo, e.g. "8.8.8.8"
    ];

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
      system-features       = ["big-parallel"];
      build-dir             = nix-daemon-build-dir;
      keep-outputs          = true;
      keep-derivations      = true;
      # Disable global flake registry
      flake-registry        = "";
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

  security.pki.certificateFiles = [ certificateFile ];

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

  # Do not download any new firmware without my input.
  services.fwupd.enable = false;

  services.locate = {
    enable    = true;
    package   = pkgs.mlocate;
    interval  = "daily";
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

  environment.etc = {
    "xdg/kglobalshortcutsrc".text = pkgs.lib.generators.toINI {} {
      # Disable Application Launcher menu when Win-key is pressed, inspired by https://askubuntu.com/questions/1256305/how-do-i-prevent-application-launcher-pop-up-when-win-key-is-pressed-in-kde.
      "plasmashell" = {
        "activate application launcher" = "";
      };
    };
  };

  environment.plasma6.excludePackages = [
    pkgs.kdePackages.elisa
    pkgs.kdePackages.kpeople
    pkgs.kdePackages.kwallet
    pkgs.kdePackages.kwallet-pam
    pkgs.kdePackages.kwalletmanager
    pkgs.kdePackages.milou
    pkgs.kdePackages.plasma-systemmonitor
  ];

  # # Set desktop wallpaper on login
  # systemd.user.services.set-wallpaper = {
  #   description = "Set KDE Plasma wallpaper";
  #   wantedBy = [ "graphical-session.target" ];
  #   after = [ "graphical-session.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.libsForQt5.plasma-workspace}/bin/plasma-apply-wallpaperimage /home/mathias/bgimage";
  #     Restart = "no";
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

  systemd = {

    services = {
      nix-daemon.environment.TMPDIR = nix-daemon-build-dir;

      # Make nix-daemon be able to download git repositories through proxy.
      nix-daemon.environment.NIX_GIT_SSL_CAINFO = certificateFile;
      nix-daemon.environment.NIX_SSL_CERT_FILE  = certificateFile;

      nixos-wsl-systemd-fix = {
        description = "Fix the /dev/shm symlink to be a mount";
        unitConfig = {
          DefaultDependencies         = "no";
          Before                      = "sysinit.target";
          ConditionPathExists         = "/dev/shm";
          ConditionPathIsSymbolicLink = "/dev/shm";
          ConditionPathIsMountPoint   = "/run/shm";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = [
            "${pkgs.coreutils-full}/bin/rm /dev/shm"
            "/run/wrappers/bin/mount --bind -o X-mount.mkdir /run/shm /dev/shm"
          ];
        };
        wantedBy = [ "sysinit.target" ];
      };
    };

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
    user = {
      extraConfig =
        ''
          DefaultLimitNOFILE=8192:262144
        '';

      # Disable rootless docker at startup - it will start automatically when docker is used.
      services.docker.wantedBy = pkgs.lib.mkForce [];
    };
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
    ports       = [ 2023 ];
    extraConfig = "PubkeyAcceptedKeyTypes = ssh-rsa,ssh-ed25519";
    settings    = {
      PermitRootLogin        = "no";
      PasswordAuthentication = false;
      UsePAM                 = false;
      X11Forwarding          = true;
    };
  };

  # zramSwap = {
  #   enable        = true;
  #   algorithm     = "zstd";
  #   memoryPercent = 50;
  # };

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

  # Disable ksgrd_network_helper within security.wrappers since the executable
  # is patched out and does not exist.
  security.wrappers.ksgrd_network_helper = { enable = pkgs.lib.mkForce false; };

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
  system.stateVersion = "24.05"; # Did you read the comment?
}

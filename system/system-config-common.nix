{ nix-daemon-build-dir }:

{ config, pkgs, ... }:
{
  # Will activate home-manager profiles for each user upon login
  # This is useful when using ephemeral installations
  environment.loginShellInit = ''
    [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
  '';

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
      pkgs.trix
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
    font = "Lat2-Terminus16";
    keyMap = "dvorak";
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
  };

  networking = {
    firewall = {
      enable = true;
      allowPing = false;
      extraCommands = ''
        iptables -I OUTPUT 1 -m owner --gid-owner no-internet -j DROP
      '';
    };
  };

  nix = {
    channel.enable = false;
    gc.automatic   = false;
    package        = pkgs.nixVersions.stable;
    settings       = {
      allowed-users         = [ "@wheel" "nix-ssh" ];
      bash-prompt-prefix    = "[nix] ";
      # Enable commands like ‘nix search’ and flakes.
      experimental-features = [ "nix-command" "flakes" ];
      # accept-flake-config = true;
      # More at https://nixos.org/nix/manual/#conf-system-features.
      system-features       = [ "big-parallel" ];
      build-dir             = nix-daemon-build-dir;
      keep-outputs          = true;
      keep-derivations      = true;
      # Disable global flake registry
      flake-registry        = "";
    };
    # extraOptions = pkgs.lib.optionalString (config.nix.package == pkgs.nixVersions.stable)
    #   "experimental-features = nix-command flakes";

    daemonCPUSchedPolicy    = "idle";
    daemonIOSchedClass      = "idle";
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
    hostKeyAlgorithms = [
      "ssh-ed25519"
      "ssh-rsa"
    ];
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
    pubkeyAcceptedKeyTypes = [
      "ssh-ed25519"
      "ssh-rsa"
    ];
  };

  security.sudo = {
    enable             = true;
    execWheelOnly      = true;
    wheelNeedsPassword = true;
    extraRules         = [
      {
        users    = [ "sergey" ];
        commands = [
          {
            command = "ALL";
            options = [ "SETENV" "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  services.acpid.enable = true;

  # Do not download any new firmware without my input.
  services.fwupd.enable = false;

  services.locate = {
    enable   = true;
    package  = pkgs.mlocate;
    interval = "daily";
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

  systemd = {
    services = {
      nix-daemon.environment.TMPDIR = nix-daemon-build-dir;
    };
    settings.Manager = {
      # File limit.
      DefaultLimitNOFILE      = "8192:10485760";
      # Timeout for starting jobs that hang for any reason.
      DefaultTimeoutStopSec   = "10s";
      DefaultDeviceTimeoutSec = "10s";
    };
    user = {
      extraConfig = ''
        DefaultLimitNOFILE=8192:262144
      '';

      # Disable rootless docker at startup - it will start automatically when docker is used.
      services.docker.wantedBy = pkgs.lib.mkForce [ ];
    };

    tmpfiles.rules = [
      "d ${nix-daemon-build-dir} 0755 root root 7d -"
      # Never clear /tmp directory
      "q /tmp                    1777 root root - -"
      "q /tmp/tmp                1777 root root - -"
      # Clear /var/tmp whenever as it was by default.
      "q /var/tmp                1777 root root - 30d"
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/London";

  users = {
    # Make sure that users are managed only through configuration.nix
    mutableUsers = false;
    groups = {
      no-internet = { };
    };
    users = {
      #};
      ## Define a user account. Don't forget to set a password with ‘passwd’.
      #extraUsers = {
      root = {
        hashedPassword = "Yeah, like I'm going to tell you even my password hash";
      };
      sergey = {
        home = "/home/sergey";
        extraGroups = [
          "adm"
          "adbusers"
          "audio"
          # # To make joysticks work, cf https://github.com/libsdl-org/SDL/issues/12397
          # NixOS doesn’t seem to have this group so doesn’t help.
          # "input"
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

  services.openssh = {
    enable      = true;
    extraConfig = "PubkeyAcceptedKeyTypes = ssh-rsa,ssh-ed25519";
    settings    = {
      PermitRootLogin        = "no";
      PasswordAuthentication = false;
      UsePAM                 = false;
      X11Forwarding          = true;
    };
  };

  system = {
    autoUpgrade = {
      enable = false;
      allowReboot = false;
    };
    # Include everything required to build every package on the system.
    # includeBuildDependencies = true;
  };

  fonts.fontconfig  = {
    enable          = true;
    hinting.style   = "full";
    antialias       = true;
  };

  # Disable ksgrd_network_helper within security.wrappers since the executable
  # is patched out and does not exist.
  security.wrappers.ksgrd_network_helper = {
    enable = pkgs.lib.mkForce false;
  };


}

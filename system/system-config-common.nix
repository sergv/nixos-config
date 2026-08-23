{ nix-daemon-build-dir }:

{ config, pkgs, flake-self, ... }:
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
      pkgs.man
      pkgs.man-pages
      pkgs.trix
      pkgs.vim
      # pkgs.nix-bash-completions
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

  system.configurationRevision = flake-self.rev or flake-self.dirtyRev or null;

}

{ config, pkgs, sergv, ... }:
{
  # Path to home manager’s activate script doesn’t exist at the time of
  # writing on 26.05.
  #
  # # Will activate home-manager profiles for each user upon login
  # # This is useful when using ephemeral installations
  # environment.loginShellInit = ''
  #   [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
  # '';

  # To be able to manipulate gtk settings.
  programs.dconf.enable = true;

  services.acpid.enable = true;

  # Do not download any new firmware without my input.
  services.fwupd.enable = false;

  services.locate = {
    enable   = true;
    package  = pkgs.mlocate;
    interval = "weekly";
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
    };

    tmpfiles.rules = [
      # Never clear /tmp directory
      "q /tmp                    1777 root root - -"
      "q /tmp/tmp                1777 root root - -"
      # Clear /var/tmp whenever as it was by default.
      "q /var/tmp                1777 root root - 30d"
    ];
  };

  system = {
    autoUpgrade = {
      enable      = false;
      allowReboot = false;
    };
    # Include everything required to build every package on the system.
    # includeBuildDependencies = true;
  };

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
      pkgs.mkpasswd
      pkgs.pciutils
      pkgs.sudo
      pkgs.strace
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

  users = {
    users = {
      "${config.sergv.user.name}" = {
        extraGroups = [
          "adm"
          "adbusers"
          "audio"
          # # To make joysticks work, cf https://github.com/libsdl-org/SDL/issues/12397
          # NixOS doesn’t seem to have this group so doesn’t help.
          # "input"
          "netdev"
          "networkmanager"
          "plugdev"
          "vboxusers"
          "video"
          "wheel"
        ];
      };
    };
  };
}

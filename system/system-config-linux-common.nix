{ config, pkgs, ... }:
{
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

  networking = {
    firewall = {
      enable = true;
      allowPing = false;
      extraCommands = ''
        iptables -I OUTPUT 1 -m owner --gid-owner no-internet -j DROP
      '';
    };
  };

  users = {
    # Make sure that users are managed only through configuration.nix
    groups = {
      no-internet = { };
    };
    users = {
      sergey = {
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
      };
    };
  };

}

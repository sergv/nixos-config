# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # TODO: add certificate file and reference it here
  certificateFile = null;
in
{

  wsl = {
    enable      = true;
    defaultUser = "sergey";
    wslConf     = {
      network.generateResolvConf = false;
    };
  };

  # environment.etc = {
  #   # Maybe try this if ssh server doesn’t work.
  #   "ssh/ssh_host_rsa_key".source         = "/permanent/etc/ssh/ssh_host_rsa_key";
  #   "ssh/ssh_host_rsa_key.pub".source     = "/permanent/etc/ssh/ssh_host_rsa_key.pub";
  #   "ssh/ssh_host_ed25519_key".source     = "/permanent/etc/ssh/ssh_host_ed25519_key";
  #   "ssh/ssh_host_ed25519_key.pub".source = "/permanent/etc/ssh/ssh_host_ed25519_key.pub";
  # };
  # List services that you want to enable:

  networking = {
    # Supreme Commander’s faf cilent doesn’t work with IPv6 at all.
    enableIPv6 = false;
    hostName = "nixos"; # Define your hostname.
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

    # Declarative successor of iptables
    # nftables = {
    #   enable = true;
    # };
  };

  nix = {
    sshServe = {
      enable  = true;
      keys    = [ "TODO: add public key here" ];
      trusted = false;
    };
  };

  # todo
  # security.pki.certificateFiles = [ certificateFile ];

  systemd = {

    services = {
      # Not strictly required: default nixpkgs setup seems to be enough.
      # # Make nix-daemon be able to download git repositories through proxy.
      # nix-daemon.environment.NIX_GIT_SSL_CAINFO = certificateFile;
      # nix-daemon.environment.NIX_SSL_CERT_FILE  = certificateFile;

      nixos-wsl-systemd-fix = {
        description = "Fix the /dev/shm symlink to be a mount";
        unitConfig  = {
          DefaultDependencies         = "no";
          Before                      = "sysinit.target";
          ConditionPathExists         = "/dev/shm";
          ConditionPathIsSymbolicLink = "/dev/shm";
          ConditionPathIsMountPoint   = "/run/shm";
        };
        serviceConfig = {
          Type      = "oneshot";
          ExecStart = [
            "${pkgs.coreutils-full}/bin/rm /dev/shm"
            "/run/wrappers/bin/mount --bind -o X-mount.mkdir /run/shm /dev/shm"
          ];
        };
        wantedBy = [ "sysinit.target" ];
      };
    };
  };

  services.openssh = {
    ports = [ 2023 ];
  };

  # zramSwap = {
  #   enable        = true;
  #   algorithm     = "zstd";
  #   memoryPercent = 50;
  # };

  system = {
    nixos.label = "wsl";
  };

  # Disable loading extra kernel modules after boot to avoid security holes.
  security.lockKernelModules = true;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-linux";

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

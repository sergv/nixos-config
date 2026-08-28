{ config, lib, pkgs, sergv, ... }:
{
  options.sergv.wsl = {
    certificate-file = lib.mkOption {
      type        = lib.types.nullOr lib.types.path;
      description = "Path to certificate file for proxy";
    };
  };

  imports = [ sergv.inputs.NixOS-WSL.nixosModules.wsl ];

  config =
    lib.mkMerge
      [
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

          networking = {
            hostName = "nixos"; # Define your hostname.
            #hostName              = ""; # Use dhcp-provided hostname.
            # networkmanager.enable = true;
            # wireless.enable       = true;  # Enables wireless support via wpa_supplicant.

            # Prefer eth0 to eno1 and the like.
            usePredictableInterfaceNames = true;

            nameservers = [
              # Todo, e.g. "8.8.8.8"
            ];

            proxy.noProxy = "127.0.0.1,localhost";
          };

          systemd = {
            services = {
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

        (lib.mkIf (config.sergv.wsl.certificate-file != null)
          {
            security.pki.certificateFiles = [ config.sergv.wsl.certificate-file ];
            sergv.programs.git.proxy.sslCAInfo = config.sergv.wsl.certificate-file;
            sergv.programs.git.proxy.sslCAPath = config.sergv.wsl.certificate-file;

            # Not strictly required: default nixpkgs setup seems to be enough.
            # systemd.services =
            #   {
            #     # Make nix-daemon be able to download git repositories through proxy.
            #     nix-daemon.environment.NIX_GIT_SSL_CAINFO = config.sergv.wsl.certificate-file;
            #     nix-daemon.environment.NIX_SSL_CERT_FILE  = config.sergv.wsl.certificate-file;
            #   };
          })
      ];
}

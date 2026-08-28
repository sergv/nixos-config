{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.sergv.system.compressed-root = {
    enable = lib.mkEnableOption "Enable mounting / as tmpfs with compression";

    size = lib.mkOption {
      type        = lib.types.str;
      default     = "20G";
      example     = "2G";
      description = "Maximum size of the compressed file that will back root partition.";
    };

    # Will get assigned automatically, no need for user to touch this.
    device = lib.mkOption {
      type        = lib.types.nullOr lib.types.int;
      default     = 1;
      example     = 1;
      description = "Name of ZRAM device that will back tmpfs with compression. When setting to XXX make sure /dev/zramXXX resolves to the correct device. Will get assigned automatically so usually there's no need to change this manually.";
    };
  };

  config =
    let
      # Not needed since 26.05
      # # Should be enough to use vanilla ‘pkgs.pkgsStatic.btrfs-progs’
      # # but they’re unbuildable in 25.05.
      # btrfs   = pkgs.pkgsStatic.btrfs-progs;
      # busybox = pkgs.pkgsStatic.busybox;

      # btrfs = pkgs.pkgsMusl.btrfs-progs;

      #   .overrideAttrs (old: {
      #
      #   version = "6.12";
      #
      #   src = pkgs.fetchurl {
      #     # url = "mirror://kernel/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v6.13.tar.xz";
      #     # hash = "sha256-ZbPyERellPgAE7QyYg7sxqfisMBeq5cTb/UGx01z7po=";
      #     url = "mirror://kernel/linux/kernel/people/kdave/btrfs-progs/btrfs-progs-v6.12.tar.xz";
      #     hash = "sha256-mn2WUf/VL75SEqjkhSo82weePSI/xVBOalCwupbNIKE=";
      #
      #
      #   };
      # })
      # #   overrideAttrs (old: {
      # #   configureFlags = (old.configureFlags or []) ++ [
      # #     # AC_FUNC_MALLOC is broken on cross builds.
      # #     "ac_cv_func_malloc_0_nonnull=yes"
      # #     "ac_cv_func_realloc_0_nonnull=yes"
      # #   ];
      # # })
      # ;

      dev = "zram${builtins.toString config.sergv.system.compressed-root.device}";

    in
    lib.mkIf config.sergv.system.compressed-root.enable
      {
        # boot.initrd.systemd.emergencyAccess = true;
        # systemd.enableEmergencyMode = true;

        # Works before ‘/’ is mounted.
        boot = {
          initrd = {
            availableKernelModules = [ "loop" ];
            kernelModules = [ "loop" ];
            supportedFilesystems = {
              btrfs = true;
            };
            verbose = true;

            systemd = {
              enable = true;

              # These tools are already present.
              # extraBin = [pkgs.pkgsStatic.btrfs-progs pkgs.pkgsStatic.busybox];

              services = {
                "zram-init-root" = {
                  after      = [ "dev-${dev}.device" ];
                  wants      = [ "dev-${dev}.device" ];
                  before     = [ "sysroot.mount" ];
                  wantedBy   = [ "sysroot.mount" ];
                  # before     = [ "mkfs-dev-${dev}.service" ];
                  # requiredBy = [ "mkfs-dev-${dev}.service" ];

                  unitConfig = {
                    # needed to prevent a cycle
                    DefaultDependencies = false;
                  };

                  serviceConfig = {
                    Restart         = "no";
                    Type            = "oneshot";
                    RemainAfterExit = "yes";
                    # ExecStop        = "${pkgs.runtimeShell} -c 'echo 1 > /sys/class/block/${dev}/reset'";
                  };
                  # NB order of initialization is important
                  # Make ramdisk never occupy more RAM with this:
                  # echo $(( 20 * 1024 * 1024 * 1024 )) > /sys/block/${dev}/mem_limit
                  script = ''
                    echo lzo-rle > /sys/block/${dev}/comp_algorithm
                  echo "priority=1 level=19" > /sys/block/${dev}/algorithm_params
                  echo "algo=zstd priority=1" > /sys/block/${dev}/recomp_algorithm
                  echo ${config.sergv.system.compressed-root.size} > /sys/block/${dev}/disksize

                  mkfs.btrfs --force /dev/${dev}
                  '';
                };
              };
            };
          };
        };

        systemd.services = {
          "zram-finish-root" = {
            after    = [ "local-fs.target" ];
            wants    = [ "local-fs.target" ];
            before   = [ "sysinit.target" ];
            wantedBy = [ "sysinit.target" ];

            unitConfig = {
              # needed to prevent a cycle
              DefaultDependencies = false;
            };

            serviceConfig = {
              Restart         = "no";
              Type            = "oneshot";
              RemainAfterExit = "yes";
              # ExecStop        = "${pkgs.runtimeShell} -c 'echo 1 > /sys/class/block/${dev}/reset'";
            };
            # echo $(( 20 * 1024 * 1024 * 1024 )) > /sys/block/${dev}/mem_limit
            # NB order of initialization is important
            script = ''
              echo "type=idle priority=1" > /sys/block/${dev}/recompress
            # Pages not accessed for two hours get marked as idle.
            echo $(( 2 * 60 * 60 )) > /sys/block/${dev}/idle
            '';
            restartIfChanged = false;
          };
        };

        # We only have two zram devices configured, the rest is added via hot add.
        # KERNEL=="zram[2-9]*", ENV{SYSTEMD_WANTS}="zram-init-%k.service", TAG+="systemd"
        services.udev.extraRules = ''
          KERNEL=="${dev}", ENV{SYSTEMD_WANTS}="zram-init-root.service", TAG+="systemd"
        '';

        # Compressed tmpfs root, includes /tmp.
        fileSystems."/" = {
          fsType  = "btrfs";
          device  = "/dev/${dev}";
          options = [
            "noatime"
            "nodiratime"
            "lazytime"
            "compress-force=zstd:8"
            # "x-systemd.after=nixos-create-root.service"
            # "noautodefrag"
          ];
        };
      };
}

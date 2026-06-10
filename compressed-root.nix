{
  self,
  config,
  lib,
  pkgs,
  ...
}:
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

in
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
            after      = [ "dev-zram1.device" ];
            wants      = [ "dev-zram1.device" ];
            before     = [ "sysroot.mount" ];
            wantedBy   = [ "sysroot.mount" ];
            # before     = [ "mkfs-dev-zram1.service" ];
            # requiredBy = [ "mkfs-dev-zram1.service" ];

            unitConfig = {
              # needed to prevent a cycle
              DefaultDependencies = false;
            };

            serviceConfig = {
              Restart         = "no";
              Type            = "oneshot";
              RemainAfterExit = "yes";
              # ExecStop        = "${pkgs.runtimeShell} -c 'echo 1 > /sys/class/block/zram0/reset'";
            };
            # NB order of initialization is important
            # Make ramdisk never occupy more RAM with this:
            # echo $(( 20 * 1024 * 1024 * 1024 )) > /sys/block/zram1/mem_limit
            script = ''
              echo lzo-rle > /sys/block/zram1/comp_algorithm
              echo "priority=1 level=19" > /sys/block/zram1/algorithm_params
              echo "algo=zstd priority=1" > /sys/block/zram1/recomp_algorithm
              echo 20G > /sys/block/zram1/disksize

              mkfs.btrfs --force /dev/zram1
            '';
          };
        };
      };
    };
  };

  # We only have two zram devices configured, the rest is added via hot add.
  # KERNEL=="zram[2-9]*", ENV{SYSTEMD_WANTS}="zram-init-%k.service", TAG+="systemd"
  services.udev.extraRules = ''
    KERNEL=="zram0", ENV{SYSTEMD_WANTS}="zram-init-swap.service", TAG+="systemd"
    KERNEL=="zram1", ENV{SYSTEMD_WANTS}="zram-init-root.service", TAG+="systemd"
  '';

  # Compressed tmpfs root, includes /tmp.
  fileSystems."/" = {
    fsType  = "btrfs";
    device  = "/dev/zram1";
    options = [
      "noatime"
      "nodiratime"
      "lazytime"
      "compress-force=zstd:8"
      # "x-systemd.after=nixos-create-root.service"
      # "noautodefrag"
    ];
  };
}

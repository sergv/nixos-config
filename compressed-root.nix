{ self, config, lib, pkgs, ... }:
let backing-store = "/dev/shm/compressed-root";

    # Should be enough to use vanilla ‘pkgs.pkgsStatic.btrfs-progs’
    # but they’re unbuildable in 25.05.
    btrfs = pkgs.pkgsStatic.btrfs-progs;

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

in {

  # Works before ‘/’ is mounted.
  boot = {
    initrd = {
      availableKernelModules = ["loop"];
      kernelModules          = ["loop"];

      postDeviceCommands = ''
        dd if=/dev/zero of=/dev/shm/compressed-root bs=1M count=10240
        ${btrfs}/bin/mkfs.btrfs --force "${backing-store}"
      '';
    };
  };

  # Compressed tmpfs root, includes /tmp.
  fileSystems."/" = {
    fsType        = "btrfs";
    device        = "${backing-store}";
    options       = ["noatime" "nodiratime" "lazytime" "compress-force=zstd:8" # "noautodefrag"
                    ];
  };
}

{ self, config, lib, pkgs, ... }:
let backing-store = "/dev/shm/compressed-root";
in {

  # Works before ‘/’ is mounted.
  boot = {
    initrd = {
      availableKernelModules = ["loop"];
      kernelModules          = ["loop"];

      postDeviceCommands = ''
        dd if=/dev/zero of=/dev/shm/compressed-root bs=1M count=10240
        ${pkgs.pkgsStatic.btrfs-progs}/bin/mkfs.btrfs --force "${backing-store}"
      '';
    };
  };

  # Compressed tmpfs root, includes /tmp.
  fileSystems."/" = {
    fsType        = "btrfs";
    device        = "${backing-store}";
    options       = ["noatime" "nodiratime" "lazytime" "compress-force=zstd:15" # "noautodefrag"
                    ];
  };
}

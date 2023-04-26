{ self, config, pkgs, ... }: {
  # nixosModules.zramMount = { config, pkgs, ... }: {

    # Copied from <nixpkgs>/nixos/modules/config/zram.nix
    system.requiredKernelConfig = [
      config.lib.kernelConfig.isModule "ZRAM"
    ];

    # Works before ‘/’ is mounted.
    boot = {
      extraModprobeConfig = ''
        options zram num_devices=1
      '';
      initrd = {
        availableKernelModules = ["zram"];
        kernelModules          = ["zram"];
        # services.udev.rules = ''
        #   ACTION == "add", KERNEL == "zram0", ATTR{comp_algorithm} = "zstd", ATTR{disksize} = "10G", RUN = "${pkgs.e2fsprogs}/sbin/mkfs.ext4 -F -m 0 -O ^has_journal /dev/%k"
        # '';
        services.udev.rules = ''
          ACTION == "add", KERNEL == "zram0", ATTR{comp_algorithm} = "zstd", ATTR{disksize} = "10G"
        '';
        postDeviceCommands = ''
          ${pkgs.e2fsprogs}/sbin/mkfs.ext4 -F -m 0 -O ^has_journal /dev/zram0
        '';
        # # Setting up zram before mounting ‘/’ requires this because zram is managed by systemd.
        # systemd.enable         = true;
      };
    };

    # # # Works after ‘/’ is mounted.
    # # boot = {
    # #   kernelModules = ["zram"];
    # #   extraModprobeConfig = ''
    # #     options zram num_devices=1
    # #   '';
    # # };
    #
    # # Works after ‘/’ is mounted.
    #
    # # Create and initialize now
    # # services.udev.extraRules = ''
    # #   ACTION == "add", KERNEL == "zram0", ATTR{comp_algorithm} = "zstd", ATTR{disksize} = "10G"
    # # '';
    #
    # # Create but initialize later
    # # services.udev.extraRules = ''
    # #   ACTION == "add", KERNEL == "zram0", ENV{SYSTEMD_WANTS} = "zram-init-%k.service", TAG += "systemd"
    # # '';
    #
    # # Adjusted to not format as swap from zram module
    # systemd.services."zram-init-zram0" = {
    #   after         = ["sys-devices-virtual-block-zram0.device"];
    #   requires      = ["sys-devices-virtual-block-zram0.device"];
    #   # "-.mount" is the target to mount "/"
    #   before        = ["-.mount"];
    #   requiredBy    = ["-.mount"];
    #   script        = ''
    #     ${pkgs.util-linux}/sbin/zramctl --size 10G --algorithm zstd /dev/zram0
    #     # ${pkgs.e2fsprogs}/sbin/mkfs.ext4 -F -m 0 -O ^has_journal /dev/zram0
    #   '';
    #   serviceConfig = {
    #     Type            = "oneshot";
    #     RemainAfterExit = true;
    #     ExecStop        = "${pkgs.runtimeShell} -c 'echo 1 > /sys/class/block/zram0/reset'";
    #   };
    #   restartIfChanged               = false;
    #   unitConfig.DefaultDependencies = false; # needed to prevent a cycle
    # };
    #
    # # boot.kernelModules = ["zram"];
    # #
    # # # Adjusted to not format as swap from zram module
    # # systemd.services."zram-init-zram0" = {
    # #   after         = [];
    # #   requires      = [];
    # #   # "-.mount" is the target to mount "/"
    # #   before        = ["-.mount"];
    # #   requiredBy    = ["-.mount"];
    # #   script        = ''
    # #     modprobe zram num_devices=1
    # #     ${pkgs.util-linux}/sbin/zramctl --size 10G --algorithm zstd /dev/zram0
    # #   '';
    # #   serviceConfig = {
    # #     Type            = "oneshot";
    # #     RemainAfterExit = true;
    # #     ExecStop        = "${pkgs.runtimeShell} -c 'echo 1 > /sys/class/block/zram0/reset'";
    # #   };
    # #   restartIfChanged               = false;
    # #   unitConfig.DefaultDependencies = false; # needed to prevent a cycle
    # # };

  # Compressed tmpfs root, configured in zram.nix. Includes /tmp.
  fileSystems."/" = {
    fsType        = "ext4";
    device        = "/dev/zram0";
    # autoFormat    = true;
    # formatOptions = "-F -m 0 -O ^has_journal";
    options       = ["noatime" "nodiratime" "lazytime"];
    # noCheck       = true;
  };

  # };
  # nixosConfigurations.zram = pkgs.lib.nixosSystem {
  #   system = "x86_64-linux";
  #   modules = [
  #     self.nixosModules.zramMount
  #   ];
  # };
}

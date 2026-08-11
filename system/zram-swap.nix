{ config, pkgs, ... }:
{
  boot.kernelParams = [
    "zram.num_devices=2"
  ];

  boot.kernel.sysctl = {
    "vm.page-cluster"           = pkgs.lib.mkDefault 0;
    "vm.swappiness"             = pkgs.lib.mkDefault 180;
    "vm.watermark_boost_factor" = pkgs.lib.mkDefault 0;
    "vm.watermark_scale_factor" = pkgs.lib.mkDefault 125;
  };

  swapDevices = [
    {
      device = "/dev/zram0";
      priority = 150;
      # Unclear whether this has any effect on return of unused or idle pages to OS.
      # options  = "discard";
    }
  ];

  # zramSwap = {
  #   enable        = true;
  #   algorithm     = "zstd";
  #   memoryPercent = 33;
  # };

  systemd.services = {
    "zram-init-swap" = {
      after    = [ "dev-zram0.device" ];
      wants    = [ "dev-zram0.device" ];
      before   = [
        "dev-zram0.swap"
        "swap.target"
      ];
      wantedBy = [
        "dev-zram0.swap"
        "swap.target"
      ];

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
      script = ''
        echo lzo-rle > /sys/block/zram0/comp_algorithm
          echo "priority=1 level=19" > /sys/block/zram0/algorithm_params
          echo "algo=zstd priority=1" > /sys/block/zram0/recomp_algorithm
          echo 20G > /sys/block/zram0/disksize

          ${pkgs.util-linux}/sbin/mkswap /dev/zram0
      '';
      restartIfChanged = false;
    };

    "zram-finish-swap" = {
      after    = [ "swap.target" ];
      wants    = [ "swap.target" ];
      before   = [ "sysinit.target" ];
      wantedBy = [ "sysinit.target" ];

      unitConfig = {
        # needed to prevent a cycle
        DefaultDependencies = false;
      };

      serviceConfig = {
        Restart = "no";
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      # NB order of initialization is important
      script = ''
        echo "type=idle priority=1" > /sys/block/zram0/recompress
        # Pages not accessed for a day get marked as idle.
        echo 86400 > /sys/block/zram0/idle
      '';
      restartIfChanged = false;
    };
  };
}

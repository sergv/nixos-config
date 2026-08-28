{ config, lib, pkgs, ... }:
{
  options.sergv.system.zram-swap = {
    enable = lib.mkEnableOption "Enable swap backed by zram to increase total usable RAM";

    size = lib.mkOption {
      type        = lib.types.str;
      default     = "20G";
      example     = "2G";
      description = "Maximum size of the compressed file that will back swap.";
    };

    # Will get assigned automatically, no need for user to touch this.
    device = lib.mkOption {
      type        = lib.types.nullOr lib.types.int;
      default     = 0;
      example     = 0;
      description = "Name of ZRAM device that will be used for swap. When setting to XXX make sure /dev/zramXXX resolves to the correct device. Will get assigned automatically so usually there's no need to change this manually.";
    };
  };

  config =
    let
      dev = "zram${builtins.toString config.sergv.system.zram-swap.device}";
    in
    lib.mkIf config.sergv.system.zram-swap.enable
      {
        boot.kernel.sysctl = {
          "vm.page-cluster"           = lib.mkDefault 0;
          "vm.swappiness"             = lib.mkDefault 180;
          "vm.watermark_boost_factor" = lib.mkDefault 0;
          "vm.watermark_scale_factor" = lib.mkDefault 125;
        };

        swapDevices = [
          {
            device   = "/dev/${dev}";
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
            after    = [ "dev-${dev}.device" ];
            wants    = [ "dev-${dev}.device" ];
            before   = [
              "dev-${dev}.swap"
              "swap.target"
            ];
            wantedBy = [
              "dev-${dev}.swap"
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
              # ExecStop        = "${pkgs.runtimeShell} -c 'echo 1 > /sys/class/block/${dev}/reset'";
            };
            # NB order of initialization is important
            script = ''
              echo lzo-rle > /sys/block/${dev}/comp_algorithm
            echo "priority=1 level=19" > /sys/block/${dev}/algorithm_params
            echo "algo=zstd priority=1" > /sys/block/${dev}/recomp_algorithm
            echo ${config.sergv.system.zram-swap.size} > /sys/block/${dev}/disksize

            ${pkgs.util-linux}/sbin/mkswap /dev/${dev}
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
              echo "type=idle priority=1" > /sys/block/${dev}/recompress
            # Pages not accessed for a day get marked as idle.
            echo 86400 > /sys/block/${dev}/idle
            '';
            restartIfChanged = false;
          };
        };

        services.udev.extraRules = ''
          KERNEL=="${dev}", ENV{SYSTEMD_WANTS}="zram-init-swap.service", TAG+="systemd"
        '';
      };
}

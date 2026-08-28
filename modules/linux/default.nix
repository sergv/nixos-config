{ config, ... }:
{
  imports =
    [
      ./compressed-root.nix
      ./desktop
      ./i2p.nix
      ./kde.nix
      ./kernel
      ./nvidia.nix
      ./persistence.nix
      ./programs
      ./sudo.nix
      ./system.nix
      ./tor.nix
      ./zram-swap.nix
    ];

  config =
    let
      zram-devices =
        (if config.sergv.system.zram-swap.enable then 1 else 0) +
        (if config.sergv.system.compressed-root.enable then 1 else 0);
    in
    {
      boot.kernelParams = [
        "zram.num_devices=${builtins.toString zram-devices}"
      ];

      sergv.system = {
        # Consistently assign all zram devices we’re going to use.
        zram-swap.device       = 0;
        compressed-root.device = if zram-devices == 2 then 1 else 0;
      };
    };
}

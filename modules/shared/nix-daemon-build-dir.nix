{ config, lib, pkgs, sergv, ... }:
{
  options.sergv.system = {
    nix-daemon-build-dir = lib.mkOption {
      type        = lib.types.nullOr lib.types.str;
      default     = null;
      description = "Where nix-daemon will perform builds";
    };
  };

  config = lib.mkIf (config.sergv.system.nix-daemon-build-dir != null)
    (lib.mkMerge
      [
        {
          nix.settings.build-dir = config.sergv.system.nix-daemon-build-dir;
        }

        (lib.optionalAttrs sergv.isLinux
          {
            systemd.services.nix-daemon.environment.TMPDIR =
              config.sergv.system.nix-daemon-build-dir;

            systemd.tmpfiles.rules = [
              "d ${config.sergv.system.nix-daemon-build-dir} 0755 root root 7d -"
            ];
          })
      ]);
}

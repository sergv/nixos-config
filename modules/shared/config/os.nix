{ lib, config, pkgs, ... }:
{
  options.sergv = {
    isLinux = lib.mkOption {
      type        = lib.types.bool;
      readOnly    = true;
      description = "Whether the host is a Linux system.";
    };

    isDarwin = lib.mkOption {
      type        = lib.types.bool;
      readOnly    = true;
      description = "Whether the host is a Darwin system.";
    };

    # Impermanence options
    persistence = {
      enable = lib.mkEnableOption "Enable persistence/impermanence";

      permanent-fast-storage = lib.mkOption {
        type        = lib.types.str;
        default     = "/permanent/fast";
        description = "Storage for real data with fast access but smaller capacity";
      };
      permanent-slow-storage = lib.mkOption {
        type        = lib.types.str;
        default     = "/permanent/slow";
        description = "Storage for real data with slow access but bigger capacity";
      };
    };
  };

  config.sergv = {
    isLinux  = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;
  };
}

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

      permanent-storage-path = lib.mkOption {
        type        = lib.types.str;
        default     = "/permanent";
        description = "Where real data is located";
      };
    };
  };

  config.sergv = {
    isLinux  = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;
  };
}

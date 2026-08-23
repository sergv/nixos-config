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

      dataPrefix = lib.mkOption {
        type        = lib.types.str;
        default     = "/permanent";
        description = "Prefix for persistent data storage";
      };
    };
  };

  config.sergv = {
    isLinux  = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;

    persistence.enable = lib.mkDefault config.sergv.isLinux;
  };
}

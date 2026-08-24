# Shared System Configuration
#
# This module provides system-wide configuration that applies to both NixOS and Darwin systems.
# It includes Nix configuration, fonts, environment variables, and shell setup.
{
  config,
  lib,
  pkgs,
  sergv,
  ...
}:
{

  config =
    lib.mkMerge
      [
        {
          nix = lib.mkMerge
            [
              {
                channel.enable = false;
                gc.automatic   = false;
                package        = pkgs.nixVersions.stable;
                settings       = {
                  # Linux-only
                  # allowed-users         = [ "@wheel" "nix-ssh" ];
                  allowed-users         = [ config.sergv.user.name ];
                  trusted-users         = [ config.sergv.user.name ];
                  bash-prompt-prefix    = "[nix] ";
                  # Enable commands like ‘nix search’ and flakes.
                  experimental-features = [ "nix-command" "flakes" ];
                  # accept-flake-config = true;
                  # More at https://nixos.org/nix/manual/#conf-system-features.
                  system-features       = [ "big-parallel" ];
                  keep-outputs          = true;
                  keep-derivations      = true;
                  # Disable global flake registry
                  flake-registry        = "";
                  warn-dirty            = false;
                  auto-optimise-store   = false;
                };

                # Same as "github:NixOS/nixpkgs/nixpkgs-unstable";
                registry = {
                  "nixpkgs-unstable" = {
                    to = {
                      owner = "NixOS";
                      repo  = "nixpkgs";
                      ref   = "nixpkgs-unstable";
                      type  = "github";
                    };
                  };
                };

              }

              (lib.mkIf config.sergv.isLinux
                {
                  daemonCPUSchedPolicy    = "idle";
                  daemonIOSchedClass      = "idle";
                })

              (lib.mkIf config.sergv.isDarwin
                {
                  nrBuildUsers = 4;
                })
            ];

          environment.systemPackages =
            [
              pkgs.man
              pkgs.man-pages
              pkgs.trix
              pkgs.vim
              # pkgs.nix-bash-completions
            ];

          # Set your time zone.
          time.timeZone = "Europe/London";

          programs.bash.enable = true;
          programs.bash.completion.enable = true;

          environment.shells = [ pkgs.bash ];

        }

        (lib.optionalAttrs sergv.isLinux
          {
            console = {
              font   = "Lat2-Terminus16";
              keyMap = "dvorak";
            };

            # Select internationalisation properties.
            i18n = {
              defaultLocale = "en_GB.UTF-8";
            };
          })
      ];
}

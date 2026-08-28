{ lib, config, pkgs, sergv, ... }:
{
  options.sergv.user = {
    name = lib.mkOption {
      type        = lib.types.str;
      default     = "sergey";
      description = "Primary user name";
    };

    fullName = lib.mkOption {
      type        = lib.types.str;
      default     = "Sergey Vinokurov";
      description = "User full name";
    };

    email = lib.mkOption {
      type        = lib.types.str;
      default     = "serg.foo@gmail.com";
      description = "User email address";
    };

    gpgKey = lib.mkOption {
      type        = lib.types.nullOr lib.types.str;
      default     = "47E4DA2E6A3F58FE3F0198F4D6CD29530F98D6B8";
      description = "User GPG key";
    };

    homeDirectory = lib.mkOption {
      type        = lib.types.str;
      description = "User home directory";
    };
  };

  config = lib.mkMerge
    [
      {
        sergv.user.homeDirectory = lib.mkDefault (
          if config.sergv.isDarwin
          then
            "/Users/${config.sergv.user.name}"
          else
            "/home/${config.sergv.user.name}"
        );

        users = lib.mkMerge
          [
            (lib.optionalAttrs sergv.isLinux {
              # Make sure that users are managed only through configuration.nix
              mutableUsers = false;
            })

            {
              groups."${config.sergv.user.name}" = { };
              users = {
                root = lib.mkIf sergv.isLinux {
                  hashedPassword =
                    builtins.warn ("root password hash not set in " + __curPos.file)
                      "No hash for you";
                };
                "${config.sergv.user.name}" = lib.mkMerge
                  [
                    # Base user configuration
                    {
                      home        = config.sergv.user.homeDirectory;
                      name        = config.sergv.user.name;
                      description = config.sergv.user.name; # config.sergv.user.fullName

                      shell = pkgs.bashInteractive;

                      openssh.authorizedKeys.keys =
                        [
                          (builtins.warn ("openssh authorized keys not set in " + __curPos.file)
                            "No keys for you")
                        ];
                    }
                    # Linux-specific user configuration
                    (lib.optionalAttrs sergv.isLinux
                      {
                        isNormalUser = true;
                        group        = config.sergv.user.name;
                        uid          = 1000;

                        # mkpasswd -m sha-512       <password>
                        hashedPassword              =
                          builtins.warn ("user password hash not set in " + __curPos.file)
                            "No hash for you";

                        # hashedPasswordFile = config.sops.secrets."users/${config.sergv.user.name}".path;
                        # extraGroups        = lib.mkIf config.sergv.isLinux [ "systemd-journal" ];
                      })
                    # Darwin-specific user configuration (no extra fields needed)
                  ];
              };
            }
          ];
      }

      (lib.optionalAttrs sergv.isDarwin
        {
          system.primaryUser = config.sergv.user.name;
        })
    ];
}

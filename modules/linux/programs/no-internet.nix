{ config, lib, ... }:
{
  options.sergv.programs.no-internet = {
    enable = lib.mkEnableOption
      "Enable 'no-internet' command to run process without internet access";
  };

  config = lib.mkIf config.sergv.programs.no-internet.enable
    {
      networking = {
        firewall = {
          enable        = true;
          allowPing     = false;
          extraCommands = ''
            iptables -I OUTPUT 1 -m owner --gid-owner no-internet -j DROP
          '';
        };
      };

      users = {
        groups = {
          no-internet = { };
        };
        users = {
          "${config.sergv.user.name}" = {
            extraGroups = [
              # Doesn’t disable internet per se, but I need to be part of the group
              # to be able to run ‘no-internet’ script.
              "no-internet"
            ];
          };
        };
      };
    };
}

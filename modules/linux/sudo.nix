{ config, ... }:
{
  config =
    {
      security.sudo = {
        enable             = true;
        execWheelOnly      = true;
        wheelNeedsPassword = true;
        extraRules         = [
          {
            users    = [ "${config.sergv.user.name}" ];
            commands = [
              {
                command = "ALL";
                options = [ "SETENV" "NOPASSWD" ];
              }
            ];
          }
        ];
      };

      users = {
        users = {
          "${config.sergv.user.name}" = {
            extraGroups = [
              "sudo"
            ];
          };
        };
      };
    };
}

{ config, pkgs, lib, sergv, ... }:
{
  config = {
    home-manager.users."${config.sergv.user.name}" = {
      xsession.enable = true;

      systemd.user.tmpfiles.rules = [
        "d /tmp/cache                                            0755 sergey users - -"
        "d /tmp/cache/emacs                                      0755 sergey users - -"
        "d /tmp/windows-shared                                   0755 sergey users - -"
        "d ${config.sergv.user.homeDirectory}/.config            0755 -      -     - -"
        "d ${config.sergv.user.homeDirectory}/.local             0755 -      -     - -"
        "d ${config.sergv.user.homeDirectory}/.java              0755 -      -     - -"
        "d ${config.sergv.user.homeDirectory}/Desktop            0755 -      -     - -"

        # Forcefully symlink, removing destination if it exists.
        "L+ ${config.sergv.user.homeDirectory}/.emacs.d/compiled 0755 -      -     - /tmp/cache/emacs"
      ];

    };
  };
}

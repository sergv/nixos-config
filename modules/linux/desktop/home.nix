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

      programs.bash.shellAliases = {
        "disk-usage" = ''if command -v filelight >/dev/null 2>&1 then filelight; elif command -v baobab >/dev/null 2>&1; then nohup dbus-run-session baobab >/dev/null; else echo "Cannot find neither filelight nor baobab executables to show disk usage" >&2; fi'';
      };

      home.packages =
        [
          pkgs.baobab
          pkgs.cpu-x
          pkgs.dmidecode
          pkgs.gimp
          pkgs.gparted
          #pkgs.inkscape
          pkgs.iotop

          pkgs.kdePackages.ark
          pkgs.kdePackages.filelight # Disk usage visualization tool, alternative to baobab
          pkgs.kdePackages.okular
          pkgs.kdePackages.oxygen-icons

          pkgs.mesa-demos

          pkgs.xd
        ];
    };
  };
}

{ config, lib, pkgs, ... }:
{

  options.sergv.system.kde = {
    enable = lib.mkEnableOption "Enable KDE environment";
  };

  config = lib.mkIf config.sergv.system.kde.enable
    (lib.mkMerge
      [
        {
          # services.displayManager.defaultSession = "plasma";
          services.displayManager.defaultSession = "plasmax11";
          # services.displayManager.defaultSession = "plasma";

          environment.etc = {
            "xdg/kglobalshortcutsrc".text = lib.generators.toINI { } {
              # Disable Application Launcher menu when Win-key is pressed, inspired by
              # https://askubuntu.com/questions/1256305/how-do-i-prevent-application-launcher-pop-up-when-win-key-is-pressed-in-kde.
              "plasmashell" = {
                "activate application launcher" = "";
              };
            };
          };

          # services.xserver = {
          #   displayManager.sddm.enable = false;
          # };

          services.desktopManager = {
            # plasma5.enable = true;
            plasma6.enable = true;
          };

          programs.kde-pim.enable = false;

          environment.plasma6.excludePackages = [
            pkgs.kdePackages.elisa
            pkgs.kdePackages.kontact
            pkgs.kdePackages.kpeople
            pkgs.kdePackages.kwallet
            pkgs.kdePackages.kwallet-pam
            pkgs.kdePackages.kwalletmanager
            pkgs.kdePackages.milou
            pkgs.kdePackages.plasma-systemmonitor
          ];

          # # Set desktop wallpaper on login
          # systemd.user.services.set-wallpaper = {
          #   description = "Set KDE Plasma wallpaper";
          #   wantedBy = [ "graphical-session.target" ];
          #   after = [ "graphical-session.target" ];
          #   serviceConfig = {
          #     Type = "oneshot";
          #     ExecStart = "${pkgs.libsForQt5.plasma-workspace}/bin/plasma-apply-wallpaperimage /home/mathias/bgimage";
          #     Restart = "no";
          #   };
          # };

        }

        (lib.mkIf config.sergv.persistence.enable
          {
            home-manager.users."${config.sergv.user.name}".home.persistence = {

              "${config.sergv.persistence.permanent-storage-path}" = {
                hideMounts = true;

                directories =
                  builtins.map
                    (x: {
                      directory = x;
                      mode = "0700";
                    })
                    [
                      # KDE
                      ".config/KDE"
                      ".config/gtk-3.0"
                      ".config/gtk-4.0"
                      ".config/kde.org"
                      ".config/kdedefaults"
                      ".config/plasma-workspace"
                      ".config/qBittorrent"
                      ".config/unity3d"
                      ".config/xsettingsd"
                      ".kde"
                      ".local/share/RecentDocuments"
                      ".local/share/baloo"
                      ".local/share/dolphin"
                      ".local/share/feral-interactive"
                      ".local/share/gwenview"
                      ".local/share/kactivitymanagerd"
                      ".local/share/kate"
                      ".local/share/kcookiejar"
                      ".local/share/kded5"
                      ".local/share/klipper"
                      ".local/share/konsole"
                      ".local/share/kscreen"
                      ".local/share/ksysguard"
                      ".local/share/kwalletd"
                      ".local/share/kxmlgui5"
                      ".local/share/okular"
                      ".local/share/plasma_icons"
                      ".local/share/plasma_notes"
                      ".local/share/plasma-systemmonitor"
                      ".local/share/sddm"
                    ];

                files =
                  builtins.map
                    (x: {
                      file   = x;
                      method = "symlink";
                    })
                    [
                      # KDE, prefers symlinks - bind mounts cannot be overwritten in-place which has led to
                      # following issues previously (may or may not be relevant any more):
                      # - broken plasma config from nixpkgs and konsole.
                      # - KDE shortcuts are not preserved between reboots.
                      ".config/PlasmaUserFeedback"
                      ".config/Trolltech.conf"
                      ".config/akregatorrc"
                      ".config/baloofileinformationrc"
                      ".config/baloofilerc"
                      ".config/bluedevilglobalrc"
                      ".config/device_automounter_kcmrc"
                      ".config/dolphinrc"
                      ".config/filetypesrc"
                      ".config/gtkrc"
                      ".config/gtkrc-2.0"
                      ".config/gwenviewrc"
                      ".config/kaccessrc-pluginsrc"
                      ".config/kactivitymanagerd-pluginsrc"
                      ".config/kactivitymanagerd-statsrc"
                      ".config/kactivitymanagerd-switcher"
                      ".config/kactivitymanagerdrc"
                      ".config/katemetainfos"
                      ".config/katerc"
                      ".config/kateschemarc"
                      ".config/katevirc"
                      ".config/kcmfonts"
                      ".config/kcminputrc"
                      ".config/kconf_updaterc"
                      ".config/kded5rc"
                      ".config/kded_device_automounterrc"
                      ".config/kdeglobals"
                      ".config/kfontinstuirc"
                      ".config/kgammarc"
                      ".config/kglobalshortcutsrc"
                      ".config/khotkeysrc"
                      ".config/kiorc"
                      ".config/kmenueditrc"
                      ".config/kmixrc"
                      ".config/konsolerc"
                      ".config/konsolesshconfig"
                      ".config/krunnerrc"
                      ".config/kscreenlockerrc"
                      ".config/kservicemenurc"
                      ".config/ksmserverrc"
                      ".config/ksplashrc"
                      ".config/ktimezonedrc"
                      ".config/kuriikwsfilterrc"
                      ".config/kwalletrc"
                      ".config/kwinrc"
                      ".config/kwinrulesrc"
                      ".config/kxkbrc"
                      ".config/mimeapps.list"
                      ".config/okularpartrc"
                      ".config/okularrc"
                      ".config/partitionmanagerrc"
                      ".config/plasma-localerc"
                      ".config/plasma-nm"
                      ".config/plasma-org.kde.plasma.desktop-appletsrc"
                      ".config/plasmanotifyrc"
                      ".config/plasmarc"
                      ".config/plasmashellrc"
                      ".config/plasmawindowed-appletsrc"
                      ".config/plasmawindowedrc"
                      ".config/powerdevilrc"
                      ".config/powermanagementprofilesrc"
                      ".config/spectaclerc"
                      ".config/startkderc"
                      ".config/systemmonitorrc"
                      ".config/systemsettingsrc"
                      ".config/user-dirs.locale"

                      ".local/share/krunnerstaterc"
                      ".local/share/recently-used.xbel"
                      ".local/share/user-places.xbel"
                      ".local/share/user-places.xbel.bak"
                      ".local/share/user-places.xbel.tbcache"

                      ".local/state/dolphinstaterc"
                      ".local/state/kickerstaterc"
                      ".local/state/konsolestaterc"
                      ".local/state/plasmashellstaterc"
                      ".local/state/systemsettingsstaterc"
                    ];
              };
            };
          })
      ]);
}

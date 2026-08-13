{
  ...
}:
{
  home.persistence = {
    "/permanent/storage" = {
      hideMounts = true;

      directories =
        builtins.map
          (x: {
            directory = x;
            mode = "0700";
          })
          [
            "Music"
            "Pictures"
            "Videos"
            "audiobooks"
            "books"
            "comics"
            "films"
            "gamedev"
            "games"
            "manga"
            "software"
            "tmp"
          ];
    };

    "/permanent" = {
      hideMounts = true;

      directories = [

        # {
        #   directory = ".local/share/Steam";
        #   method = "symlink";
        # }

        # Pulseaudio doesn’t like symlinks.
        ".config/pulse"
      ]
      ++
        builtins.map
          (x: {
            directory = x;
            mode = "0700";
          })
          [
            "Documents"
            "Downloads"
            "My Games"
            "London"
            "VirtualBox VMs"
            "art"
            "bicycle"
            "documents"
            "dwhelper"
            "health"
            "nix"
            "projects"
            "recipes"
            "scripts"
            "sites"
            "todo"
            "torrents"
            "travelling"

            # Supreme Commander FAF
            # ".gapforever"
            ".faforever"

            ".android"
            ".bitcoin"
            ".cabal"
            ".cargo"
            ".dosbox"
            ".electrum"
            ".emacs.d"
            ".ghc"
            ".ghc-wasm"
            ".gnupg"
            ".gradle"
            ".isabelle"
            ".java/.userPrefs"
            ".litecoin"
            ".mozilla"
            ".paradoxlauncher"
            ".ssh"
            ".stack"
            ".thunderbird"

            ".config/.arduino15"
            ".config/AndroidStudio3.2"
            ".config/Google"
            ".config/PCSX2"
            ".config/VirtualBox"
            ".config/Xilinx"
            ".config/android"
            ".config/audacious"
            ".config/bitcoin"
            ".config/chromium"
            ".config/dconf"
            ".config/fontforge"
            ".config/htop"
            ".config/ksysguardrc"
            ".config/keybase"
            ".config/libreoffice"
            ".config/mc"
            ".config/paradox-launcher-v2"
            ".config/ristretto"
            ".config/strawberry"
            ".config/transmission"
            ".config/vlc"
            ".config/xfce4"
            ".local/share/3909"
            ".local/share/Anki"
            ".local/share/Anki2"
            ".local/share/Paradox Interactive"
            ".local/share/TelegramDesktop"
            ".local/share/Tyranny"
            ".local/share/aspyr-media"
            ".local/share/direnv"
            ".local/share/docker"
            ".local/share/keyrings"
            ".local/share/mc"
            ".local/share/mime"
            ".local/share/openmw"
            ".local/share/qBittorrent"
            ".local/share/ristretto"
            ".local/share/strawberry"
            ".local/share/trash"
            ".local/share/vlc"

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

      files = [
        "machine-specific-setup.el"
        "password.org"
        "todo.org"
        "O0DGDxpMBNs.jpg"
        ".aspell.en.prepl"
        ".aspell.en.pws"
        ".bash_history"
        ".rtorrent.rc"
        ".vimrc"
        ".config/Audaciousrc"
        ".config/QtProject.conf"
        ".config/Triblerrc"
        ".local/ghci.conf"
      ]
      ++
        builtins.map
          (x: {
            file = x;
            method = "symlink";
          })
          [
            # ".emacs"

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
}

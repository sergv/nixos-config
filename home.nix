{ config, pkgs, nixpkgs-fresh-ghc, system, ... }:

let wmctrl-pkg = pkgs.wmctrl;

    my-fonts = import ./fonts { inherit pkgs; };

    scripts = import ./scripts { inherit pkgs; wmctrl = wmctrl-pkg; };

    dev-pkgs = import ./dev-pkgs.nix { inherit pkgs nixpkgs-fresh-ghc system; };

    wm-sh = scripts.wm-sh;

    game-run-wrapper = pkgs.writeScriptBin "game-run" ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.steam-run}/bin/steam-run "''${@}"
    '';

    isabelle-icon = ./icons/isabelle.svg;

    isabelle-pkg = pkgs.isabelle.overrideAttrs (oldAttrs:
      let newDesktopItem = pkgs.makeDesktopItem {
            name        = "isabelle";
            exec        = "isabelle jedit";
            icon        = isabelle-icon;
            desktopName = "Isabelle";
            comment     = "A generic proof assistant";
            categories  = ["Math"];
          };
      in
        {
          desktopItem = newDesktopItem;
          installPhase =
            builtins.replaceStrings
              [ # "${oldAttrs.desktopItem}"
                "cp \"$out/Isabelle${oldAttrs.version}/lib/icons/isabelle.xpm\" \"$out/share/icons/hicolor/isabelle/apps/\""
                "cp -r \"${oldAttrs.desktopItem}/share/applications\" \"$out/share/applications\""
                # "${oldAttrs.desktopItem}"
              ]
              [ # "${desktopItem}"
                # ""
                "ln -s \"${isabelle-icon}\" \"$out/share/icons/hicolor/isabelle/apps/isabelle.svg\""
                "ln -s \"${newDesktopItem}/share/applications\" \"$out/share/applications\""
                # "${newDesktopItem}"
              ]
              oldAttrs.installPhase;
          # postInstall = builtins.replaceStrings [ "${oldAttrs.desktopItem}" ] [ "${newDesktopItem}" ] oldAttrs.postInstall;
        }
    );

    emacs-pkg = (pkgs.emacs.override (old: { nativeComp = false; })).overrideAttrs (old: {
      patches = (old.patches or []) ++ [
        ./patches/emacs-gc-block-increase.patch
      ];
      nativeComp = false;
    });

    emacs-wrapped = pkgs.writeScriptBin "emacs" ''
      #!${pkgs.bash}/bin/bash
      if [[ ! -z "''${EMACS_ROOT+x}" ]]; then
          dump_file="$EMACS_ROOT/emacs.dmp"
      else
          dump_file="$HOME/.emacs.d/emacs.dmp"
      fi

      if [[ ! -f "$dump_file" || ! -z "''${EMACS_FORCE_PRISTINE+x}" ]]; then
        ${emacs-pkg}/bin/emacs "''${@}"
      else
        ${emacs-pkg}/bin/emacs --dump-file "$dump_file" "''${@}"
      fi
    '';

    emacsDesktopItem = pkgs.lib.generators.toINI {} {
      "Desktop Entry" = {
        Type = "Application";
        Exec = "${emacs-wrapped}/bin/emacs %u";
        Terminal = false;
        Name = "Emacs";
        Icon = "emacs";
        Comment = "Edit text";
        GenericName = "Text Editor";
        MimeType = pkgs.lib.concatMapStrings (s: s + ";") emacsMimeTypes;
        Categories = "Utility;TextEditor;";
        StartupWMClass = "Emacs";
      };
    };

    emacsMimeTypes = [
      "application/x-shellscript"
      "text/english"
      "text/plain"
      "text/x-c"
      "text/x-c++"
      "text/x-c++hdr"
      "text/x-c++src"
      "text/x-chdr"
      "text/x-csrc"
      "text/x-java"
      "text/x-haskell"
      "text/x-makefile"
      "text/x-moc"
      "text/x-pascal"
      "text/x-tcl"
      "text/x-tex"
      "x-scheme-handler/org-protocol"
    ];

in
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    #stateVersion = "22.05";

    username      = "sergey";
    homeDirectory = "/home/sergey";
    stateVersion  = "22.05";

    keyboard = {
      layout  = "us,ru";
      variant = "dvorak,";
      options = [ "grp:shifts_toggle" "caps:escape" ];
    };
  };

  fonts.fontconfig.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash = {
    enable           = true;
    historyControl   = [ "ignorespace" "ignoredups" "erasedups" ];
    historyFileSize  = 100000;

    shellOptions     = [ "histappend" "checkwinsize" "globstar" ];
    initExtra        =
      # Note that bash variables in there are quoted with '',
      # strip them before feeding to bash
      ''
        #export PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"
        export PROMPT_COMMAND="history -a"

        export PS1="\u@\h:\w\$ "

        function genpasswd {
            local len="$1"
            tr -dc 'A-Za-z_0-9:$#!@*+|' </dev/urandom | head -c "''${len:-20}" | cat && echo
        }

        function openurl {
            local file="$(mktemp -u --tmpdir urls/tmp.XXXXXXXX)"
            local dir="''${TMPDIR:-/tmp}/urls"
            [[ ! -d "''${dir}" ]] && mkdir -p "''${dir}"
            wget -k "$1" -O "$file"
            if [[ -f "$file" ]]; then
                firefox -new-tab "$file"
            else
                echo "url $1 not downloaded"
            fi
        }

        # Download site recursively
        function download-site () {
            local url="$1"
            if [[ -z "$url" ]]; then
                echo "usage: download-site URL"
                return
            fi
            # --sockets=1 --connection-per-second=1 --max-rate=65536
            httrack --mirror --connection-per-second=1 --max-rate=65536 --structure=1 --keep-alive "$url"
        }

        function hp2pdf () {
            if [[ "$#" != 1 || "$1" != *.hp ]]; then
                echo "usage: hp2pdf <hp-file>" >&2
                return
            fi
            filename="$1"
            abs_file="$(readlink -f $1)"
            echo hp2ps -M -c -d "$abs_file" #-g -y
            hp2ps -M -c -d "$abs_file" #-g -y
            echo ps2pdf "''${filename%.hp}.ps"
            ps2pdf "''${filename%.hp}.ps"
            okular "''${filename%.hp}.pdf"
        }

      '';

    shellAliases     = {
      "igrep"               = "grep -iHn --color=auto";
      "grep"                = "grep -Hn --color=auto";
      "egrep"               = "grep -EHn --color=auto";
      "fgrep"               = "grep -FHn --color=auto";

      "ls"                  = "ls --color=always";
      "lla"                 = "ls --human-readable -AlFa --color=always";
      "ll"                  = "ls --human-readable -AlF --color=always";
      "la"                  = "ls -A --color=always";
      "l"                   = "ls -CF --color=always";

      ".."                  = "cd ..";
      "..."                 = "cd ../..";
      "...."                = "cd ../../..";

      "diff"                = "diff --unified --recursive --ignore-tab-expansion --ignore-blank-lines";
      "diffw"               = "diff --unified --recursive --ignore-tab-expansion --ignore-space-change --ignore-blank-lines";

      "youtube-dl-playlist" = "youtube-dl --write-description --add-metadata -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' --output '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'";
      "youtube-dl-single"   = "youtube-dl --write-description --add-metadata -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' --output '%(title)s.%(ext)s'";
      "youtube-dl-audio"    = "youtube-dl --add-metadata -f 'bestaudio[ext=m4a]' --output '%(title)s.%(ext)s'";

      "baobab-new"          = "nohup dbus-run-session baobab >/dev/null";

    };
    sessionVariables = {
      "HIE_BIOS_CACHE_DIR"        = "/tmp/dist/hie-bios";
      "EMACS_ROOT"                = "/home/sergey/.emacs.d";
      "EMACS_SYSTEM_TYPE"         = "(linux home)";
      "CCACHE_COMPRESS"           = "1";
      "CCACHE_DIR"                = "/tmp/.ccache";
      "CCACHE_NOSTATS"            = "1";
      # So that latex will pick up .cls/.sty files from current directory
      "TEXINPUTS"                 = ".:";
      "EMAIL"                     = "serg.foo@gmail.com";
      "BASHRC_ENV_LOADED"         = "1";
    };
  };

  programs.git = {
    enable    = true;
    userName  = "Sergey Vinokurov";
    userEmail = "serg.foo@gmail.com";
    signing   = {
      key = "47E4DA2E6A3F58FE3F0198F4D6CD29530F98D6B8";
      signByDefault = true;
    };
    aliases   = {
      "lg"  = "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(red)%h %G?%C(reset)%C(yellow)%d%C(reset) %C(white)%s%C(reset) - %C(dim white)%an%C(reset) %C(green)(%ar)%C(reset)'";
      "lgm" = "lg --no-merges";
      "ch"  = "checkout";
      "st"  = "status";
      "co"  = "commit";
      "me"  = "merge";
      "br"  = "branch";
      "m"   = "merge";
    };
    includes = [
      { contents = {
          advice = {
            # Disable `git status' hints on how to stage, etc.
            statusHints         = false;
	          graftFileDeprecated = false;
          };
          branch = {
            # When branching off a remote branch, automatically let the local
            # branch track the remote one.
            autosetupmerge = true;
          };
          color = {
            ui = true;
          };
          diff = {
            # Make git diff use mnemonic prefixes (Index, Work tree, etc) instead
            # of standard a/ & b/ prefixes.
            mnemonicprefix = true;
            # Show more informative diff when submodules are involved.
            submodule = "log";
          };
          merge = {
            # Always show a diffstat at the end of merge.
            stat = true;
          };
          rebase = {
            # Always show a diffstat at the end of rebase.
            stat = true;
          };
          rerere = {
            enabled = true;
            # Autostage files solved by rerere
            autoupdate = true;
          };
          status = {
            # Provide more information on sumbodule changes in "git status"
            submoduleSummary = true;
          };
          pull = {
            # Automatically rebase when doing "git pull" but preserve local merges.
	          # This is the value for git < 2.34
	          #rebase = preserve
	          # This is the value for git >= 2.34
	          rebase = "merges";
            # Fetch submodules when superproject retrieves commit that updates
            # submodule's reference.
            recurseSubmodules = "on-demand";
          };
          fetch = {
            # Fetch submodules when superproject retrieves commit that updates
            # submodule's reference.
            recurseSubmodules = "on-demand";
          };
          push = {
            default = "simple";
            # Check that all submodule commits that current commit to be pushed
            # references are already pushed somewhere.
            recurseSubmodules = "check";
          };
          init = {
	          defaultBranch = "master";
          };
        };
      }
    ];
    ignores = [
      ".eproj-info"
      "cabal-project*.local"
      "dist-newstyle*"
      "dist"
      "*~"
      "*.bak"
    ];
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname     = "github.com";
        user         = "git";
        identityFile = "/home/sergey/.ssh/github_sergv_id_rsa";
      };
      "gitlab.haskell.org" = {
        hostname     = "gitlab.haskell.org";
        user         = "git";
        identityFile = "/home/sergey/.ssh/haskell-ghc-gitlab-key";
      };
    };
  };

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable          = true;
    defaultCacheTtl = 3600000000;
    maxCacheTtl     = 3600000000;
    pinentryFlavor  = "qt";
  };

  services.sxhkd = {
    enable      = true;
    keybindings = {
      # "super + t"          = "exo-open --launch TerminalEmulator";
      "mod4 + t"           = "konsole";

      "KP_Insert"          = "; ${wm-sh}/bin/wm.sh swap";
      "XF86Go"             = "; ${wm-sh}/bin/wm.sh swap";
      "KP_End"             = "; ${wm-sh}/bin/wm.sh switch 0";

      "KP_Down"            = "; ${wm-sh}/bin/wm.sh switch 1";
      "KP_Next"            = "; ${wm-sh}/bin/wm.sh switch 2";
      "KP_Left"            = "; ${wm-sh}/bin/wm.sh switch 3";
      "KP_Begin"           = "; ${wm-sh}/bin/wm.sh switch 4";
      "KP_Right"           = "; ${wm-sh}/bin/wm.sh switch 5";
      "KP_Home"            = "; ${wm-sh}/bin/wm.sh switch 6";
      "KP_Up"              = "; ${wm-sh}/bin/wm.sh switch 7";
      "KP_Prior"           = "; ${wm-sh}/bin/wm.sh switch 8";
      "KP_Delete"          = "; ${wm-sh}/bin/wm.sh switch 9";
      "KP_Divide"          = "; ${wm-sh}/bin/wm.sh backward";
      "KP_Multiply"        = "; ${wm-sh}/bin/wm.sh forward";
      # "XF86Mail"         = "; /tmp/wm_operate.py --pop";
      "mod4 + XF86Go"      = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -b toggle,fullscreen";

      # "Alt + Left"       = "; /tmp/wm_operate.py --backward";
      # "Alt + Right"      = "; /tmp/wm_operate.py --forward";

      "shift + KP_End"     = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 0";
      "shift + KP_Down"    = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 1";
      "shift + KP_Next"    = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 2";
      "shift + KP_Left"    = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 3";
      "shift + KP_Begin"   = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 4";
      "shift + KP_Right"   = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 5";
      "shift + KP_Home"    = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 6";
      "shift + KP_Up"      = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 7";
      "shift + KP_Prior"   = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 8";
      "shift + KP_Delete"  = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 9";

      # Kinesis Advantage mappings

      "mod4 + 1"           = "; ${wm-sh}/bin/wm.sh switch 0";
      "mod4 + 2"           = "; ${wm-sh}/bin/wm.sh switch 1";
      "mod4 + 3"           = "; ${wm-sh}/bin/wm.sh switch 2";
      "mod4 + 4"           = "; ${wm-sh}/bin/wm.sh switch 3";
      "mod4 + 5"           = "; ${wm-sh}/bin/wm.sh switch 4";
      "mod4 + 6"           = "; ${wm-sh}/bin/wm.sh switch 5";
      "mod4 + 7"           = "; ${wm-sh}/bin/wm.sh switch 6";
      "mod4 + 8"           = "; ${wm-sh}/bin/wm.sh switch 7";
      "mod4 + 9"           = "; ${wm-sh}/bin/wm.sh switch 9";
      "mod4 + 0"           = "; ${wm-sh}/bin/wm.sh switch 10";

      "mod4 + F1"          = "; ${wm-sh}/bin/wm.sh switch 0";
      "mod4 + F2"          = "; ${wm-sh}/bin/wm.sh switch 1";
      "mod4 + F3"          = "; ${wm-sh}/bin/wm.sh switch 2";
      "mod4 + F4"          = "; ${wm-sh}/bin/wm.sh switch 3";
      "mod4 + F5"          = "; ${wm-sh}/bin/wm.sh switch 4";
      "mod4 + F6"          = "; ${wm-sh}/bin/wm.sh switch 5";
      "mod4 + F7"          = "; ${wm-sh}/bin/wm.sh switch 6";
      "mod4 + F8"          = "; ${wm-sh}/bin/wm.sh switch 7";
      "mod4 + F9"          = "; ${wm-sh}/bin/wm.sh switch 8";
      "mod4 + F10"         = "; ${wm-sh}/bin/wm.sh switch 9";
      "mod4 + F11"         = "; ${wm-sh}/bin/wm.sh switch 10";
      "mod4 + F12"         = "; ${wm-sh}/bin/wm.sh switch 11";

      "control + mod4 + 1" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 0";
      "control + mod4 + 2" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 1";
      "control + mod4 + 3" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 2";
      "control + mod4 + 4" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 3";
      "control + mod4 + 5" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 4";
      "control + mod4 + 6" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 5";
      "control + mod4 + 7" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 6";
      "control + mod4 + 8" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 7";
      "control + mod4 + 9" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 9";
      "control + mod4 + 0" = "; ${wmctrl-pkg}/bin/wmctrl -r :ACTIVE: -t 10";

      "mod4 + Prior"       = "; ${wm-sh}/bin/wm.sh swap";
    };
  };

  xsession.enable = true;

  systemd.user.tmpfiles.rules = [
    "d /tmp/cache           0755 sergey users - -"
    "d /home/sergey/.config -    -      -     - -"
    "d /home/sergey/.local  -    -      -     - -"
    "d /home/sergey/Desktop -    -      -     - -"
  ] ++ map
    (x:
      # Forcefully symlink, removing source if it exists.
      "L+ \"/home/sergey/${x}\" - - - - /permanent/home/sergey/${x}"
    )
    [
        ".emacs"
        "machine-specific-setup.el"

        ".bash_history"
        ".rtorrent.rc"
        ".viminfo"
        ".vimrc"

        ".config/Audaciousrc"
        ".config/QtProject.conf"

        ".local/ghci.conf"
        ".local/share/recently-used.xbel"

        "github-recovery-codes.txt"
        #"mars.exe"
        "password.org"
        "todo.org"

        "O0DGDxpMBNs.jpg"

        ".aspell.en.prepl"
        ".aspell.en.pws"

        # KDE
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
        ".config/kgammarc"
        ".config/kglobalshortcutsrc"
        ".config/kfontinstuirc"
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
        ".config/PlasmaUserFeedback"
        ".config/plasmawindowed-appletsrc"
        ".config/plasmawindowedrc"
        ".config/powerdevilrc"
        ".config/powermanagementprofilesrc"
        ".config/spectaclerc"
        ".config/startkderc"
        ".config/systemmonitorrc"
        ".config/systemsettingsrc"
        ".config/Trolltech.conf"
        ".config/user-dirs.dirs"
        ".config/user-dirs.locale"

        ".config/PCSX2"

        ".local/share/krunnerstaterc"
        ".local/share/user-places.xbel"
        ".local/share/user-places.xbel.bak"
        ".local/share/user-places.xbel.tbcache"
    ];

  dconf.settings = {
    "org/gtk/settings/file-chooser" = {
      "sort-directories-first" = true;
    };
  };

  xdg = {
    dataFile."applications/emacs.desktop".text = emacsDesktopItem;
  };

  # xdg.userDirs = {
  #   enable            = true;
  #   createDirectories = true;
  #   documents         = "\$HOME/documents";
  #   download          = "\$HOME/downloads";
  #   pictures          = "\$HOME/pictures";
  #   publicShare       = "\$HOME/misc";
  #   music             = "\$HOME/misc/music";
  #   templates         = "\$HOME/templates";
  #   videos            = "\$HOME/misc/videos";
  # };

  home.packages =
    let
      tex-pkg = (pkgs.texlive.combine {
        inherit (pkgs.texlive)
          scheme-small
          dvisvgm dvipng # for preview and export as html
          wrapfig
          amsmath
          ulem
          hyperref

          arydshln
          fontawesome5
          moderncv
          multirow

          capt-of
          collection-basic
          collection-binextra
          collection-context
          collection-fontsrecommended
          collection-fontutils
          collection-langenglish
          collection-latex
          collection-latexrecommended
          collection-luatex
          collection-metapost
          collection-texworks
          collection-xetex

          fncychap
          framed
          needspace
          tabulary
          titlesec
          varwidth;
      });
    in
      [
        pkgs.ark
        (pkgs.aspellWithDicts (d: [d.en d.en-computers d.en-science d.ru d.uk]))
        pkgs.audacious
        # pkgs.autoconf
        pkgs.baobab
        pkgs.bridge-utils
        # pkgs.ccache
        pkgs.chromium
        # pkgs.clang
        # pkgs.clang-tools
        # pkgs.coq
        pkgs.curl
        pkgs.dmidecode
        pkgs.ffmpeg
        pkgs.file
        pkgs.findutils
        #pkgs.firefox
        pkgs.firefox-esr
        pkgs.gimp
        pkgs.glxinfo
        pkgs.gparted
        pkgs.graphviz
        pkgs.htop
        pkgs.imagemagick7
        pkgs.inkscape
        pkgs.iotop
        pkgs.okular
        pkgs.libreoffice
        pkgs.lsof
        pkgs.lzip
        pkgs.lzop
        pkgs.mc
        pkgs.mplayer
        pkgs.oxygen-icons5
        pkgs.p7zip
        pkgs.pavucontrol
        pkgs.pinentry_qt
        pkgs.pmutils
        pkgs.pv
        pkgs.sshfs
        pkgs.thunderbird
        pkgs.transmission-gtk
        pkgs.unzip
        pkgs.usbutils
        pkgs.vlc
        pkgs.vorbis-tools
        pkgs.wget
        pkgs.xorg.xev
        pkgs.youtube-dl
        pkgs.zip
        # pkgs.yasm
        pkgs.zstd
        # pkgs.z3

        pkgs.cabextract
        pkgs.winePackages.stagingFull
        # pkgs.wine64Packages.stagingFull
        pkgs.winetricks

        pkgs.nix-diff

        isabelle-pkg

        game-run-wrapper

        tex-pkg
        wmctrl-pkg

        emacs-wrapped
      ] ++
      builtins.attrValues dev-pkgs ++
      builtins.attrValues my-fonts ++
      builtins.attrValues scripts;

}

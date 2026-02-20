{ config
, pkgs
, pkgs-cross-win
, pkgs-pristine
, haskell-nixpkgs-improvements
# , nixpkgs-stable
# , nixpkgs-unstable
, arkenfox
, git-proxy-conf
, arch
, system
, ...
}:

let wmctrl-pkg = pkgs.wmctrl;

    my-fonts = import ./fonts { inherit pkgs; };

    scripts = import ./scripts { inherit pkgs; wmctrl = wmctrl-pkg; };

    dev-pkgs = import ./dev-pkgs.nix {
      inherit pkgs haskell-nixpkgs-improvements arch system;
    };

    cuda-pkgs = import ./cuda-pkgs.nix {
      inherit pkgs;
    };

    byar = import ./beyond-all-reason-launcher.nix {
      inherit (pkgs-pristine)
        lib
        stdenv
        fetchFromGitHub
        buildNpmPackage
        runCommand
        nodejs
        electron
        # butler
        steam-run
        jq
        xorg
        libcxx

        gcc
        cmake
        curl
        pkg-config
        jsoncpp
        boost
        minizip;
    };

    wm-sh = scripts.wm-sh;

    steam = pkgs.steam.override (_: {
      # # Remove non-free parts.
      # steam-unwrapped = null;
      # Add 32-bit pulseaudio for Supreme Commander.
      extraLibraries = steam-pkgs: [steam-pkgs.libpulseaudio];
    });

    game-run-wrapper = pkgs.writeScriptBin "game-run" ''
      #!${pkgs.bash}/bin/bash
      exec "${steam.run}/bin/steam-run" "''${@}"
    '';

    strawberry-pkg = pkgs.strawberry.overrideAttrs (old: {
      src = pkgs.fetchgit {
        url    = "https://github.com/sergv/strawberry.git";
        rev    = "fb93e0e09454dcc154c1901c4df196271fe2d549";
        sha256 = "sha256-rrjeMg/cYSbcbbBtT/VvyXysfNnikMHXRwyiPe5Hguk="; #pkgs.lib.fakeSha256;
      };

      cmakeFlags =
        (old.cmakeFlags or []) ++
        builtins.map (x: pkgs.lib.cmakeBool x false) [
          "ENABLE_GIO"
          "ENABLE_AUDIOCD"
          "ENABLE_MTP"
          "ENABLE_GPOD"
          "ENABLE_SPOTIFY"
        ];

      # postInstall =
      #   old.postInstall + "\n" + ''
      #     qtWrapperArgs+=(--set-default QT_SCALE_FACTOR "1.25")
      #   '';
    });

    qbittorrent-pkg =
      let scale = "1.5";
          #scale = "1.0";
      in
        (pkgs.qbittorrent.override {
          webuiSupport  = false;
          trackerSearch = false;
        }).overrideAttrs (old: {

          postInstall = old.postInstall +
                        ''
          sed -i -re 's/^Exec=(.*)/Exec=env QT_SCALE_FACTOR=${scale} \1/' "$out/share/applications/org.qbittorrent.qBittorrent.desktop"
        '';
        });

    tribler-pkg =
      let tribler-python = pkgs.python310;
          libtorrent-rasterbar-1_2_x-upd =
            let version = "1.2.19";
            in
              (pkgs.libtorrent-rasterbar-1_2_x.override (old: {
                boost  = old.boost.override (_: {
                  enableStatic = true;
                  enableShared = false;
                });
                openssl = old.openssl.override (_: {
                  static = true;
                });
                python = tribler-python;
              })).overrideAttrs (old: {

                inherit version;

                src = pkgs.fetchgit {
                  url    = "https://github.com/arvidn/libtorrent.git";
                  rev    = "v${version}";
                  sha256 = "sha256-dkjNv40/B1bbY16xtYFXOgbbOFnRSp9G2eG5/6dxfgI="; # pkgs.lib.fakeSha256;
                };

                nativeBuildInputs =
                  old.nativeBuildInputs ++ [
                    tribler-python.pkgs.setuptools
                    pkgs.boost-build
                    pkgs.openssl.dev
                  ];

                preConfigure = (old.preConfigure or "") + "\n" + ''
                  configureFlagsArray+=('PYTHON_INSTALL_PARAMS=--prefix=$(DESTDIR)$(prefix) --single-version-externally-managed --record=installed-files.txt')
                '';

              });
      in
        pkgs.tribler.override (old: {
          libtorrent-rasterbar-1_2_x = libtorrent-rasterbar-1_2_x-upd;
          python3                    = tribler-python;
        });

    wine-pkg = pkgs.wineWowPackages.stagingFull;

    winetricks-pkg =
      let
        # Patch allows to point winetricks to the wine executable via WINE_BIN environment variable.
        patch = pkgs.fetchurl {
          url = "https://github.com/Winetricks/winetricks/commit/1d441b422d9a9cc8b0a53fa203557957ca1adc44.patch";
          hash = "sha256-/y7PkJ046X29QtK8uVN9ziq8co8rATcWDxPNM7Ph45I=";
        };
        patched = pkgs.winetricks.overrideAttrs (old: {
          patches = (old.patches or []) ++ [patch];
          # src = pkgs.fetchFromGitHub {
          #   owner = "Winetricks";
          #   repo = "winetricks";
          #   # rev = "bc91718a5cad45e9f33de9b351a5960d5395bed5";
          #   # sha256 = "sha256-YTEgb19aoM54KK8/IjrspoChzVnWAEItDlTxpfpS52w="; #pkgs.lib.fakeSha256;
          #   rev = "5eed63521781ffc2f0c4bbee7ec9e215b13a1243";
          #   sha256 = "sha256-thEL36C2I/l4R5YAyfVg9H3FttsslVRK06Y8rPg+7Do="; #pkgs.lib.fakeSha256;
          # };
        });
      in
        # ‘winetricks’ relies on knowing architecture of the ‘wine’
        # executable, but on NixOS the ‘wine’ executable is a shell
        # script wrapper which breaks ‘winetricks’. This export makes
        # ‘winetricks’ learn about actual ‘wine’ executable and infer
        # its architecture properly.
        pkgs.runCommand "wrapped-winetricks" {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        }
          # makeWrapper "${patched}/bin/winetricks" "$out/bin/winetricks" --set-default "WINE_BIN" "$(dirname $(readlink -f $(which wine)))/.wine"
          ''
            mkdir -p "$out/bin"
            makeWrapper "${patched}/bin/winetricks" "$out/bin/winetricks" --set-default "WINE_BIN" "${wine-pkg}/bin/.wine"
          ''

          # export WINE_BIN=$(dirname $(readlink -f $(which wine)))/.wine

          #patched
        ;

    mk-isabelle = include-emacs-lsp-fixes:
      import ./isabelle/isabelle.nix {
        inherit pkgs include-emacs-lsp-fixes;
      };

    isabelle-pkg = mk-isabelle false;

    isabelle-lsp-pkg = mk-isabelle true;

    isabelle-lsp-wrapper =

      pkgs.runCommand "isabelle-emacs-lsp" {
        buildInptus       = [ isabelle-lsp-pkg ];
        nativeBuildInputs = [];
      }
        ''
          mkdir -p "$out/bin"
          ln -s "${isabelle-lsp-pkg}/bin/isabelle" "$out/bin/isabelle-emacs-lsp"
        '';

    emacs-base = (pkgs.emacs30.override (_ : {
      withNativeCompilation = false;
      noGui = false;
      srcRepo = true;
      withXwidgets = false;
      withTreeSitter = true;
      withSQLite3 = false;
      withSelinux = false;
      withPgtk = false;
      withJansson = false; # Use native JSON in Emacs instead, aviailable since version 30.
      withGTK3 = true;
    })).overrideAttrs (old: {
      # NixOS 25.05 patches do not apply to 30.2 any more. Remove throwing away of
      # nixpkgs patches here when moving to a later NixOS release.
      # patches        = [];
      # version        = "30.2";
      withGTK3       = true;
      withSQLite3    = false;
      withTreeSitter = true;
      configureFlags = old.configureFlags ++ [
        (pkgs.lib.withFeature false "gc-mark-trace")
      ];
      src            = pkgs.fetchgit {
        url    = "https://github.com/sergv/emacs.git";
        rev    = "86023a80217c3bd16a6d18c976f56a9a54531246";
        sha256 = "sha256-PAmfVhSLgW016kJiZlkWH64d2gvsJIqBdIKKQCO8b5M="; #pkgs.lib.fakeSha256;
      };
    });

    emacs-native-pkg = (emacs-base.override (_: { withNativeCompilation = true; })).overrideAttrs (old: {
      withNativeCompilation = true;
      patches = (old.patches or []) ++ [
        (pkgs.substituteAll {
          src = ./patches/native-comp-driver-options-30.patch;

          backendPath =
            let libGccJitLibraryPaths = [
                  "${pkgs.lib.getLib pkgs.libgccjit}/lib/gcc"
                  "${pkgs.lib.getLib pkgs.stdenv.cc.libc}/lib"
                ] ++ pkgs.lib.optionals (pkgs.stdenv.cc?cc.lib.libgcc) [
                  "${pkgs.lib.getLib pkgs.stdenv.cc.cc.lib.libgcc}/lib"
                ];
            in
              pkgs.lib.concatStringsSep " "
                (builtins.map
                  (x: ''"-B${x}"'')
                  ([
                    # Paths necessary so the JIT compiler finds its libraries:
                    "${pkgs.lib.getLib pkgs.libgccjit}/lib"
                  ] ++ libGccJitLibraryPaths ++ [
                    # Executable paths necessary for compilation (ld, as):
                    "${pkgs.lib.getBin pkgs.stdenv.cc.cc}/bin"
                    "${pkgs.lib.getBin pkgs.stdenv.cc.bintools}/bin"
                    "${pkgs.lib.getBin pkgs.stdenv.cc.bintools.bintools}/bin"
                  ]));
        })
      ];
    });

    emacs-bytecode-pkg = (emacs-base.override (_: { withNativeCompilation = false; })).overrideAttrs (_: {
      withNativeCompilation = false;
    });

    emacs-debug-pkg = pkgs.enableDebugging emacs-bytecode-pkg;

    mk-emacs-pkg = exe-name: pkg: wrapper:
      pkgs.writeScriptBin exe-name ''
        #!${pkgs.bash}/bin/bash
        if [[ ! -z "''${EMACS_ROOT+x}" ]]; then
            dump_file="$EMACS_ROOT/compiled/${exe-name}.dmp"
        else
            dump_file="$HOME/.emacs.d/compiled/${exe-name}.dmp"
        fi

        if [[ ! -f "$dump_file" || "''${EMACS_FORCE_PRISTINE:-0}" != 0 ]]; then
          ${wrapper}${pkg}/bin/emacs "''${@}"
        else
          ${wrapper}${pkg}/bin/emacs --dump-file "$dump_file" "''${@}"
        fi
      '';

    emacs-native-wrapped = mk-emacs-pkg "emacs-native" emacs-native-pkg "";

    emacs-bytecode-wrapped = mk-emacs-pkg "emacs" emacs-bytecode-pkg "";

    emacs-debug-wrapped = mk-emacs-pkg "emacs-debug" emacs-debug-pkg "gdb -ex='set confirm on' -ex=run -ex=quit --args ";

in
{

  imports = [
    arkenfox.hmModules.default
  ];

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
      options = ["grp:shifts_toggle" "caps:escape"];
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash = {
    enable           = true;
    historyControl   = ["ignorespace" "ignoredups" "erasedups"];
    historyFileSize  = 100000;

    shellOptions     = ["histappend" "checkwinsize" "globstar"];
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

      # PS that shows full command lines and process tree.
      "ps-full"             = "ps auxfww";

      ".."                  = "cd ..";
      "..."                 = "cd ../..";
      "...."                = "cd ../../..";

      "diff"                = "diff --unified --recursive --ignore-tab-expansion --ignore-blank-lines";
      "diffw"               = "diff --unified --recursive --ignore-tab-expansion --ignore-space-change --ignore-blank-lines";

      "youtube-dl-playlist" = "yt-dlp --write-description --add-metadata -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' --output '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'";
      "youtube-dl-single"   = "yt-dlp --write-description --add-metadata -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' --output '%(title)s.%(ext)s'";
      "youtube-dl-audio"    = "yt-dlp --add-metadata -f 'bestaudio[ext=m4a]' --output '%(title)s.%(ext)s'";

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
    signing   = {
      key = "47E4DA2E6A3F58FE3F0198F4D6CD29530F98D6B8";
      signByDefault = true;
    };
    ignores = [
      ".eproj-info"
      "cabal-project*.local"
      "dist-newstyle*"
      "dist"
      "*~"
      "*.bak"
    ];
    settings  = {
      alias = {
        "lg"  = "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(red)%h %G?%C(reset)%C(yellow)%d%C(reset) %C(white)%s%C(reset) - %C(dim white)%an%C(reset) %C(green)(%ar)%C(reset)'";
        "lgm" = "lg --no-merges";
        "ch"  = "checkout";
        "st"  = "status";
        "co"  = "commit";
        "me"  = "merge";
        "br"  = "branch";
        "m"   = "merge";
      };
      user = {
        name  = "Sergey Vinokurov";
        email = "serg.foo@gmail.com";
      };
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
      # http = git-proxy-conf;
      # https = git-proxy-conf;
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
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname     = "github.com";
        user         = "git";
        identityFile = "/home/sergey/.ssh/github_sergv_id_rsa";
      };
      "gitlab.com" = {
        hostname     = "gitlab.com";
        user         = "git";
        identityFile = "/home/sergey/.ssh/anon-gitlab-key";
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
    enable           = true;
    defaultCacheTtl  = 3600000000;
    maxCacheTtl      = 3600000000;
    pinentry.package = pkgs-pristine.pinentry-qt;
  };

  services.sxhkd = {
    enable      = true;
    keybindings = import ./sxhkd-keybindings.nix { inherit wm-sh wmctrl-pkg; };
  };

  xsession.enable = true;

  systemd.user.tmpfiles.rules = [
    "d /tmp/cache                      0755 sergey users - -"
    "d /tmp/cache/emacs                0755 sergey users - -"
    "d /tmp/windows-shared             0755 sergey users - -"
    "d /home/sergey/.config            0755 -      -     - -"
    "d /home/sergey/.local             0755 -      -     - -"
    "d /home/sergey/.java              0755 -      -     - -"
    "d /home/sergey/Desktop            0755 -      -     - -"

    # Forcefully symlink, removing destination if it exists.
    "L+ /home/sergey/.emacs.d/compiled 0755 -      -     - /tmp/cache/emacs"

    # "L+ /home/sergey/.vimrc            0644 -      -     - /permanent/home/sergey/.vimrc"
  ];

  home.persistence = {
    "/permanent/storage" = {
      hideMounts = true;

      directories =
        builtins.map
          (x: { directory = x; mode = "0700"; })
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
      ] ++
      builtins.map
        (x: { directory = x; mode = "0700"; })
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
        ".emacs"
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
      ] ++
      builtins.map (x: { file = x; method = "symlink"; })
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
          ".config/user-dirs.dirs"
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

  dconf.settings = {
    "org/gtk/settings/file-chooser" = {
      "sort-directories-first" = true;
    };
  };

  xdg = {
    desktopEntries = {
      emacs = {
        type           = "Application";
        exec           = "emacs %u";
        terminal       = false;
        name           = "Emacs";
        icon           = ./icons/emacs.png;
        comment        = "Edit text";
        genericName    = "Text Editor";
        mimeType       = [
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
        categories     = ["Utility" "TextEditor"];
        # startupWMClass = "Emacs";
      };

      i2p = {
        type           = "Application";
        exec           = "firefox -P i2p %u";
        terminal       = false;
        name           = "I2P";
        icon           = ./icons/i2p.png;
        comment        = "Anonymous Internet";
        genericName    = "Web Browser";
        mimeType       = [];
        categories     = ["Network" "WebBrowser"];
        # startupWMClass = "I2P";
      };
    };
    # dataFile."applications/emacs.desktop".text = emacsDesktopItem;
    # dataFile."applications/i2p.desktop".text = i2pDesktopItem;
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

  programs.firefox = import ./firefox.nix {
    inherit pkgs pkgs-pristine;
    firefox-addons = pkgs.nur.repos.rycee.firefox-addons;
  };

  programs.chromium = {
    enable = true;
    # Take from pristine so that it will be picked up from cache. Building chromium
    # is almost impossible.
    # pkgs-pristine.chromium
    # pkgs.google-chrome
    package = pkgs-pristine.ungoogled-chromium;
  };

  # Same as "github:NixOS/nixpkgs/nixpkgs-unstable";
  nix.registry = {
    "nixpkgs-unstable" = {
      to = {
        owner = "NixOS";
        repo  = "nixpkgs";
        ref   = "nixpkgs-unstable";
        type  = "github";
      };
    };
  };

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
          cm-super
          type1cm

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

          bussproofs # for natural deduction notation
          fncychap
          framed
          needspace
          tabulary
          titlesec
          varwidth;
      });
    in
      [
        pkgs-pristine.anki
        (pkgs.aspellWithDicts (d: [d.en d.en-computers d.en-science d.ru d.uk]))
        # pkgs.autoconf
        pkgs.baobab
        pkgs.bridge-utils
        # pkgs.ccache
        # pkgs.clang
        # pkgs.clang-tools
        pkgs.clinfo
        pkgs.cloc
        # pkgs.coq
        pkgs.cpu-x
        pkgs.curl
        pkgs.dmidecode
        pkgs.fahclient
        pkgs.ffmpeg-full
        pkgs.file
        pkgs.findutils
        pkgs.gimp
        pkgs.gparted
        pkgs.graphviz
        pkgs.htop
        pkgs.imagemagick
        #pkgs.inkscape
        pkgs.iotop
        pkgs.kdePackages.ark
        pkgs.kdePackages.filelight # Disk usage visualization tool, alternative to baobab
        pkgs.sergv-extensions.ksysguard6
        pkgs.kdePackages.okular
        pkgs.kdePackages.oxygen-icons
        pkgs.lsof
        pkgs.lzip
        pkgs.lzop
        pkgs.mc
        pkgs.mesa-demos
        pkgs.mpv
        pkgs.nix-index
        pkgs.p7zip
        pkgs.pavucontrol

        # pkgs.pmutils
        pkgs.pv
        # for shsplit
        pkgs.shntool
        pkgs.smartmontools
        pkgs.sshfs
        pkgs-pristine.telegram-desktop
        pkgs.unrar
        pkgs.unzip
        pkgs.usbutils
        pkgs.vlc
        pkgs.vorbis-tools
        pkgs.wget
        pkgs.xorg.xev
        pkgs.yt-dlp
        pkgs.zip
        # pkgs.yasm
        pkgs.zstd
        # pkgs.z3

        # Take from pristine so that it will be picked up from cache. Building thunderbird
        # is almost impossible - linking consumes too much memory.
        pkgs-pristine.thunderbird
        pkgs-pristine.libreoffice

        # Music
        strawberry-pkg

        pkgs.i2p
        pkgs.xd

        qbittorrent-pkg
        # tribler-pkg

        pkgs.vdhcoapp

        # byar

        # pkgs.vmware-workstation

        pkgs.cabextract
        wine-pkg
        winetricks-pkg

        pkgs.nix-diff

        isabelle-pkg
        isabelle-lsp-wrapper

        pkgs.pcsx2
        game-run-wrapper

        tex-pkg
        wmctrl-pkg

        # emacs-native-wrapped
        emacs-bytecode-wrapped
        emacs-debug-wrapped
      ] ++
      # Btrfs utils
      # [ pkgs.btrfs-progs
      #   pkgs.compsize
      # ] ++
      builtins.attrValues dev-pkgs ++
      builtins.attrValues cuda-pkgs ++
      builtins.attrValues my-fonts ++
      builtins.attrValues scripts;

}

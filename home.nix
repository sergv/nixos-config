{ config
, pkgs
, pkgs-cross-win
, pkgs-pristine
, pinned-pkgs
, nixpkgs-stable
, nixpkgs-unstable
, arkenfox
, git-proxy-conf
, system
, ...
}:

let wmctrl-pkg = pkgs.wmctrl;

    my-fonts = import ./fonts { inherit pkgs; };

    scripts = import ./scripts { inherit pkgs; wmctrl = wmctrl-pkg; };

    dev-pkgs = import ./dev-pkgs.nix {
      inherit pkgs pkgs-cross-win pinned-pkgs system nixpkgs-unstable; #nixpkgs-stable
    };

    wm-sh = scripts.wm-sh;

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

    emacs-pkg = (pkgs.emacs29.override (_: { withNativeCompilation = true; })).overrideAttrs (old: {
      version               = "30.0.93";
      patches               = [
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
      withNativeCompilation = true;
      withGTK3              = true;
      withSQLite3           = true;
      withTreeSitter        = true;

      configureFlags = old.configureFlags ++ [
        (pkgs.lib.withFeature false "gc-mark-trace")
      ];

      src                   = pkgs.fetchgit {
        url    = "https://github.com/sergv/emacs.git";
        rev    = "f0e4d6c9f4bd68a827b116de71a0b5b4c72bfe07";
        sha256 = "sha256-mjZig+19R16oJ8Vu6G49esa4wqgDHJDswsuetLNux08="; #pkgs.lib.fakeSha256;
      };
    });

    emacs-bytecode-pkg = (emacs-pkg.override (_: { withNativeCompilation = false; })).overrideAttrs (_: {
      patchess              = [];
      withNativeCompilation = false;
      withTreeSitter        = true;
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

    emacs-wrapped = mk-emacs-pkg "emacs" emacs-pkg "";

    emacs-debug-wrapped = mk-emacs-pkg "emacs-debug" emacs-debug-pkg "gdb -ex='set confirm on' -ex=run -ex=quit --args ";

    emacs-bytecode-wrapped = mk-emacs-pkg "emacs-bytecode" emacs-bytecode-pkg "";

    emacsDesktopItem = pkgs.lib.generators.toINI {} {
      "Desktop Entry" = {
        Type           = "Application";
        Exec           = "emacs %u";
        Terminal       = false;
        Name           = "Emacs";
        Icon           = "emacs";
        Comment        = "Edit text";
        GenericName    = "Text Editor";
        MimeType       = pkgs.lib.concatMapStrings (s: s + ";") emacsMimeTypes;
        Categories     = "Utility;TextEditor;";
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

    sessionPath = ["$HOME/local/bin"];

    keyboard = {
      layout  = "us,ru";
      variant = "dvorak,";
      options = ["grp:shifts_toggle" "caps:escape"];
    };
  };

  fonts.fontconfig.enable = true;

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

      ".."                  = "cd ..";
      "..."                 = "cd ../..";
      "...."                = "cd ../../..";

      "diff"                = "diff --unified --recursive --ignore-tab-expansion --ignore-blank-lines";
      "diffw"               = "diff --unified --recursive --ignore-tab-expansion --ignore-space-change --ignore-blank-lines";

      "baobab-new"          = "nohup dbus-run-session baobab >/dev/null";
    };
    sessionVariables = {
      "HIE_BIOS_CACHE_DIR"        = "/tmp/dist/hie-bios";
      "EMACS_ROOT"                = "/home/sergey/.emacs.d";
      "EMACS_SYSTEM_TYPE"         = "(linux work)";
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
    # TODO: set up user and email
    userName  = "";
    userEmail = "";
    signing   = {
      key           = "47E4DA2E6A3F58FE3F0198F4D6CD29530F98D6B8";
      signByDefault = false;
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
          http = git-proxy-conf;
          https = git-proxy-conf;
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
    enable          = true;
    defaultCacheTtl = 3600000000;
    maxCacheTtl     = 3600000000;
    pinentryPackage = pkgs.pinentry-qt;
  };

  services.sxhkd = {
    enable      = true;
    keybindings = import ./sxhkd-keybindings.nix { inherit wm-sh wmctrl-pkg; };
  };

  xsession.enable = true;

  systemd.user.tmpfiles.rules = [
    "d /tmp/emacs-cache                0755 sergey users - -"
    "d /tmp/cache                      0755 sergey users - -"
    "d /tmp/cache/gradle-caches        0755 sergey users - -"
    "d /tmp/cache/gradle-daemon        0755 sergey users - -"
    "d /tmp/windows-shared             0755 sergey users - -"
    "d /home/sergey/.config            -    -      -     - -"
    "d /home/sergey/.local             -    -      -     - -"
    "d /home/sergey/.java              -    -      -     - -"
    "d /home/sergey/Desktop            -    -      -     - -"

    # Forcefully symlink, removing destination if it exists.
    "L+ /home/sergey/.emacs.d/compiled -    -      -     - /tmp/emacs-cache"
    "L+ /home/sergey/.gradle/caches    -    -      -     - /tmp/cache/gradle-caches"
    "L+ /home/sergey/.gradle/daemon    -    -      -     - /tmp/cache/gradle-daemon"
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

  programs.firefox = import ./firefox.nix {
    inherit pkgs;
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
        pkgs.ark
        (pkgs.aspellWithDicts (d: [d.en d.en-computers d.en-science d.ru d.uk]))
        pkgs.baobab
        pkgs.clinfo
        pkgs.cloc
        pkgs.cpu-x
        pkgs.curl
        pkgs.dmidecode
        pkgs.fahclient
        pkgs.ffmpeg-full
        pkgs.file
        pkgs.findutils
        pkgs.gimp
        pkgs.glxinfo
        pkgs.gparted
        pkgs.graphviz
        pkgs.gwenview
        pkgs.htop
        pkgs.imagemagick
        pkgs.iotop
        pkgs.okular
        pkgs.libreoffice
        pkgs.lsof
        pkgs.lzip
        pkgs.lzop
        pkgs.maxima
        pkgs.mc
        pkgs.mplayer
        pkgs.nix-index
        pinned-pkgs.nixpkgs-22-11.nyx
        pkgs.oxygen-icons5
        pkgs.p7zip
        pkgs.pv
        pkgs.shntool
        pkgs.smartmontools
        pkgs.sshfs
        pkgs.unzip
        pkgs.usbutils
        pkgs.vorbis-tools
        pkgs.wget
        pkgs.xorg.xev
        pkgs.yt-dlp
        pkgs.zip
        pkgs.zstd

        # Music
        pkgs.xd

        pkgs.nix-diff

        isabelle-pkg
        isabelle-lsp-wrapper

        tex-pkg
        wmctrl-pkg

        pkgs.wineWowPackages.stable

        emacs-wrapped
        emacs-bytecode-wrapped
        emacs-debug-wrapped
        pkgs.tree-sitter
      ] ++
      # Btrfs utils
      # [ pkgs.btrfs-progs
      #   pkgs.compsize
      # ] ++
      builtins.attrValues dev-pkgs ++
      builtins.attrValues my-fonts ++
      builtins.attrValues scripts;

}

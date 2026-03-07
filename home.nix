{
  config,
  pkgs,
  pkgs-opt,
  pkgs-cross-win,
  pkgs-pristine,
  haskell-nixpkgs-improvements,
  # , nixpkgs-stable
  # , nixpkgs-unstable
  arkenfox,
  git-proxy-conf,
  arch,
  system,
  ...
}:

let
  wmctrl-pkg = pkgs.wmctrl;

  my-fonts = import ./fonts { inherit pkgs; };

  scripts = import ./scripts {
    inherit pkgs;
    wmctrl = wmctrl-pkg;
  };

  dev-pkgs = import ./dev-pkgs.nix {
    inherit haskell-nixpkgs-improvements arch system;
    pkgs = pkgs-opt;
  };

  wm-sh = scripts.wm-sh;

  mk-isabelle =
    include-emacs-lsp-fixes:
    import ./isabelle/isabelle.nix {
      inherit pkgs include-emacs-lsp-fixes;
    };

  isabelle-pkg = mk-isabelle false;

  isabelle-lsp-pkg = mk-isabelle true;

  isabelle-lsp-wrapper =

    pkgs.runCommand "isabelle-emacs-lsp"
      {
        buildInptus = [ isabelle-lsp-pkg ];
        nativeBuildInputs = [ ];
      }
      ''
        mkdir -p "$out/bin"
        ln -s "${isabelle-lsp-pkg}/bin/isabelle" "$out/bin/isabelle-emacs-lsp"
      '';

  emacs-base =
    (pkgs-opt.emacs30.override (_: {
      withNativeCompilation = false;
      noGui = false;
      srcRepo = true;
      withTreeSitter = true;
      withSQLite3 = false;
      withPgtk = false;
      withJansson = false; # Use native JSON in Emacs instead, aviailable since version 30.

      withX = true;
      withGTK3 = true;
      withToolkitScrollBars = false;
      withCairo = true;
      withXinput2 = true;

      withAcl = false;
      withAlsaLib = false;
      withMailutils = false;
      withGcMarkTrace = false;
      withImageMagick = false;
      withXwidgets = false;
      withDbus = false;
      withSelinux = false;

      # Disable General Purpose Mouse (GPM), a background service that
      # provides mouse support for the Linux console (the text-only
      # TTY you see before logging into a graphical desktop). Unless
      # you plan to use Emacs in a bare-metal Linux console (outside
      # of a terminal emulator like Alacritty, Foot, or GNOME
      # Terminal), GPM is unnecessary. Modern terminal emulators use
      # their own internal protocols for mouse interaction that do not
      # rely on the GPM daemon.
      withGpm = false;

    })).overrideAttrs
      (old: {
        src = pkgs.fetchgit {
          url = "https://github.com/sergv/emacs.git";
          rev = "3b9730ce5522861b30e66d1f925baba1ca1fe34b";
          sha256 = "sha256-56c26FA/RQhy9pnHz9/BJFB2DFyM4Q1wUWzrIKeSiko="; # pkgs.lib.fakeSha256;
        };

        # NixOS 25.05 patches do not apply to 30.2 any more. Remove throwing away of
        # nixpkgs patches here when moving to a later NixOS release.
        patches = [ ];
        # version        = "30.2";

        configureFlags = old.configureFlags ++ [
          # https://www.jamescherti.com/compiling-emacs/
          "--enable-link-time-optimization"
          "--enable-largefile"
          "--disable-xattr"

          (pkgs.lib.withFeature true "harfbuzz")
          (pkgs.lib.withFeature true "gnutls")

          (pkgs.lib.withFeature true "gsettings")
          (pkgs.lib.withFeature true "threads")
          (pkgs.lib.withFeature true "libgmp")
          (pkgs.lib.withFeature true "xml2")
          (pkgs.lib.withFeature true "zlib")
          (pkgs.lib.withFeatureAs true "file-notification" "inotify")

          (pkgs.lib.withFeature true "wide-int")

          (pkgs.lib.withFeature true "xpm")
          (pkgs.lib.withFeature true "png")
          (pkgs.lib.withFeature true "rsvg")
          (pkgs.lib.withFeature false "tiff")
          (pkgs.lib.withFeature true "jpeg")
          (pkgs.lib.withFeature false "gif")

          (pkgs.lib.withFeatureAs true "pdumper" "yes")
          (pkgs.lib.withFeatureAs true "unexec" "no")
          (pkgs.lib.withFeatureAs true "dumping" "pdumper")

          (pkgs.lib.withFeature false "xft")
          (pkgs.lib.withFeature false "libotf")
          (pkgs.lib.withFeature false "xim")
          (pkgs.lib.withFeature false "gconf")
          (pkgs.lib.withFeature false "sound")
          (pkgs.lib.withFeature false "libsystemd")
          (pkgs.lib.withFeature false "libsmack")
          (pkgs.lib.withFeature false "kerberos")
          (pkgs.lib.withFeature false "pop")
          (pkgs.lib.withFeature false "kerberos5")
          (pkgs.lib.withFeature false "hesiod")
          (pkgs.lib.withFeature false "mail-unlink")
          (pkgs.lib.withFeature false "lcms2")

          # Disables the X11 Double Buffer Extension. This protocol is
          # redundant for modern builds because both the PGTK (Wayland)
          # and GTK3 (X11) layers handle window buffering internally.
          # Disabling it simplifies the binary and ensures Emacs uses
          # modern rendering paths.
          (pkgs.lib.withFeature false "xdbe")
        ];

        CFLAGS = "-O2 -pipe -march=${arch.gccArch} -mtune=${arch.gccArch} -fno-omit-frame-pointer -fno-plt -flto=auto";
        LDFLAGS = "-Wl,-O2 -Wl,-z,now -Wl,-z,relro -Wl,--sort-common -Wl,--as-needed -Wl,-z,pack-relative-relocs -flto=auto";
      });

  emacs-native-pkg =
    (emacs-base.override (_: {
      withNativeCompilation = true;
    })).overrideAttrs
      (old: {
        withNativeCompilation = true;
        # NixOS 25.05 patches do not apply to 30.2 any more. Remove throwing away of
        # nixpkgs patches here when moving to a later NixOS release.
        # patches = (old.patches or []) ++ [
        patches = [
          (pkgs.replaceVars ./patches/native-comp-driver-options-30.patch {
            nativeCpuArch = "${arch.gccArch}";

            backendPath =
              let
                libGccJitLibraryPaths = [
                  "${pkgs.lib.getLib pkgs-opt.libgccjit}/lib/gcc"
                  "${pkgs.lib.getLib pkgs-opt.stdenv.cc.libc}/lib"
                ]
                ++ pkgs.lib.optionals (pkgs-opt.stdenv.cc ? cc.lib.libgcc) [
                  "${pkgs.lib.getLib pkgs-opt.stdenv.cc.cc.lib.libgcc}/lib"
                ];
              in
              pkgs.lib.concatStringsSep " " (
                builtins.map (x: ''"-B${x}"'') (
                  [
                    # Paths necessary so the JIT compiler finds its libraries:
                    "${pkgs.lib.getLib pkgs-opt.libgccjit}/lib"
                  ]
                  ++ libGccJitLibraryPaths
                  ++ [
                    # Executable paths necessary for compilation (ld, as):
                    "${pkgs.lib.getBin pkgs-opt.stdenv.cc.cc}/bin"
                    "${pkgs.lib.getBin pkgs-opt.stdenv.cc.bintools}/bin"
                    "${pkgs.lib.getBin pkgs-opt.stdenv.cc.bintools.bintools}/bin"
                  ]
                )
              );
          })
        ];
      });

  emacs-bytecode-pkg =
    (emacs-base.override (_: {
      withNativeCompilation = false;
    })).overrideAttrs
      (_: {
        withNativeCompilation = false;
      });

  emacs-debug-pkg = pkgs.enableDebugging emacs-bytecode-pkg;

  mk-emacs-pkg =
    exe-name: pkg: wrapper:
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

  emacs-debug-wrapped =
    mk-emacs-pkg "emacs-debug" emacs-debug-pkg
      "gdb -ex='set confirm on' -ex=run -ex=quit --args ";

in
{

  imports = [
    arkenfox.hmModules.default
  ];

  # Disable all home-manager manuals - the manpages fails on WSL because of
  # non-functional Semaphore within Python.
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

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
    stateVersion = "22.05";

    sessionPath = [ "$HOME/local/bin" ];

    keyboard = {
      layout = "us,ru";
      variant = "dvorak,";
      options = [
        "grp:shifts_toggle"
        "caps:escape"
      ];
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    historyControl = [
      "ignorespace"
      "ignoredups"
      "erasedups"
    ];
    historyFileSize = 100000;

    shellOptions = [
      "histappend"
      "checkwinsize"
      "globstar"
    ];
    initExtra =
      # Note that bash variables in there are quoted with '',
      # strip them before feeding to bash
      ''
        #export PROMPT_COMMAND="''${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a"
        export PROMPT_COMMAND="history -a"

        nix_shell_prompt() {
            # Check if IN_NIX_SHELL variable is set.
            if [[ -v IN_NIX_SHELL ]]; then
                echo "[nix]"
            fi
        }

        export PS1='$(nix_shell_prompt)\u@\h:\w\$ '

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

    shellAliases = {
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

      "baobab-new" = "nohup dbus-run-session baobab >/dev/null";
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
      # ‘nix-shell’ likes to change prompt. ‘trix’ uses ‘nix-shell’ as underlying mechanism
      # so is affected too, while ‘nix develop’ doesn’t so set up this variable to make
      # ‘trix develop’ # behave more like ‘nix develop’.
      "NIX_SHELL_PRESERVE_PROMPT" = "1";
    };
  };

  programs.git = {
    enable  = true;
    signing = {
      key           = "47E4DA2E6A3F58FE3F0198F4D6CD29530F98D6B8";
      signByDefault = false;
    };
    ignores = [
      ".eproj-info"
      "cabal-project*.local"
      "dist-newstyle*"
      "dist"
      "*~"
      "*.bak"
    ];
    settings = {
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
        # TODO: set up user and email
        name  = "";
        email = "";
      };
      advice = {
        # Disable `git status' hints on how to stage, etc.
        statusHints = false;
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
      safe = {
        # Let me decide what is considered ‘dubious ownership in
        # repository’, i.e. git, shut the fuck up.
        directory = "*";
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
        hostname = "gitlab.com";
        user = "git";
        identityFile = "/home/sergey/.ssh/anon-gitlab-key";
      };
      "gitlab.haskell.org" = {
        hostname = "gitlab.haskell.org";
        user = "git";
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

    # "L+ /home/sergey/.emacs            0644 -      -     - /permanent/home/sergey/.emacs"

    # "L+ /home/sergey/.vimrc            0644 -      -     - /permanent/home/sergey/.vimrc"
  ];

  dconf.settings = {
    "org/gtk/settings/file-chooser" = {
      "sort-directories-first" = true;
    };
  };

  xdg = {
    # Disable xdg-desktop-portal-gtk which brings gnome-settings-daemon as dependency.
    portal.extraPortals = pkgs.lib.mkForce [ pkgs.xdg-desktop-portal-kde ];

    desktopEntries = {
      emacs = {
        type        = "Application";
        exec        = "emacs %u";
        terminal    = false;
        name        = "Emacs";
        icon        = ./icons/emacs.png;
        comment     = "Edit text";
        genericName = "Text Editor";
        categories  = [
          "Utility"
          "TextEditor"
        ];
        mimeType    = [
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
        # startupWMClass = "Emacs";
      };

      i2p = {
        type             = "Application";
        exec             = "firefox -P i2p %u";
        terminal         = false;
        name             = "I2P";
        icon             = ./icons/i2p.png;
        comment          = "Anonymous Internet";
        genericName      = "Web Browser";
        mimeType         = [ ];
        categories       = [
          "Network"
          "WebBrowser"
        ];
        # startupWMClass = "I2P";
      };
    };
    # dataFile."applications/emacs.desktop".text = emacsDesktopItem;
    # dataFile."applications/i2p.desktop".text = i2pDesktopItem;

    userDirs = {
      enable              = true;
      createDirectories   = true;
      setSessionVariables = false;
      desktop             = "$HOME/Desktop";
      documents           = "$HOME/Documents";
      download            = "$HOME/Downloads";
      music               = "$HOME/Music";
      pictures            = "$HOME/Pictures";
      videos              = "$HOME/Videos";
      projects            = null;
    };
  };

  programs.firefox = import ./firefox.nix {
    inherit pkgs pkgs-opt pkgs-pristine;
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
      tex-pkg = (
        pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-small
            dvisvgm
            dvipng # for preview and export as html
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
            varwidth
            ;
        }
      );
    in
    [
      (pkgs.aspellWithDicts (d: [
        d.en
        d.en-computers
        d.en-science
        d.ru
        d.uk
      ]))
      pkgs.baobab
      pkgs.clinfo
      pkgs.cloc
      pkgs.cpu-x
      pkgs.curl
      pkgs.dmidecode
      pkgs.fahclient
      pkgs-opt.ffmpeg
      # pkgs-opt.ffmpeg-full
      # (pkgs-opt.ffmpeg-full.override (old: {
      #   # frei0r-plugins doesn’t build.
      #   withFrei0r    = false;
      #   withSamba     = false;
      #   withStripping = true;
      # }))
      pkgs.file
      pkgs.findutils
      pkgs.gimp
      pkgs.gparted
      pkgs-opt.graphviz
      pkgs-opt.htop
      pkgs.imagemagick
      pkgs.iotop
      pkgs.kdePackages.ark
      pkgs.kdePackages.filelight # Disk usage visualization tool, alternative to baobab
      pkgs.sergv-extensions.ksysguard6
      pkgs.kdePackages.gwenview
      pkgs.kdePackages.okular
      pkgs.kdePackages.oxygen-icons
      pkgs.lsof
      pkgs-opt.lzip
      pkgs-opt.lzop
      pkgs.maxima
      pkgs-opt.mc
      pkgs.mesa-demos
      pkgs-opt.mpv
      pkgs.nix-index
      pkgs-opt.p7zip

      pkgs.pv
      pkgs.shntool
      pkgs.smartmontools
      pkgs.sshfs
      pkgs-opt.unzip
      pkgs.usbutils
      pkgs-opt.vorbis-tools
      pkgs.wget
      pkgs.xev
      pkgs.yt-dlp
      pkgs-opt.zip
      # pkgs.yasm
      pkgs-opt.zstd
      # pkgs.z3

      # Take from pristine so that it will be picked up from cache. Building thunderbird
      # is almost impossible - linking consumes too much memory.
      pkgs-pristine.thunderbird
      pkgs-pristine.libreoffice

      pkgs.xd

      pkgs-opt.nix-diff

      isabelle-pkg
      isabelle-lsp-wrapper

      tex-pkg
      wmctrl-pkg

      pkgs.wineWow64Packages.stable

      emacs-native-wrapped
      emacs-bytecode-wrapped
      emacs-debug-wrapped
    ]
    ++
      # Btrfs utils
      # [ pkgs.btrfs-progs
      #   pkgs.compsize
      # ] ++
      builtins.attrValues dev-pkgs
    ++ builtins.attrValues my-fonts
    ++ builtins.attrValues scripts;

}

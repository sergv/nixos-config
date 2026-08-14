{
  # home manager config
  config,
  # NixOS config
  osConfig,
  # pkgs created by nixos configuration
  pkgs,
  # my special args
  pkgs-optimised,
  pkgs-cross-win,
  pkgs-pristine,
  haskell-nixpkgs-improvements,
  dotemacs,
  git-proxy-conf,
  arch,
  system,
  ...
}:

let
  wmctrl-pkg = pkgs.wmctrl;

  pkgs-opt = if pkgs-optimised == null then pkgs else pkgs-optimised;

  homeDir = osConfig.users.users.sergey.home;

  my-fonts = import ../fonts { inherit pkgs; };

  scripts = import ../scripts {
    inherit pkgs;
    wmctrl = wmctrl-pkg;
  };

  haskell-tools =
    let
      pkgs-haskell   = pkgs-opt.appendOverlays [ haskell-nixpkgs-improvements.overlays.host ];
      # pkgs-cross-win = pkgs-opt.appendOverlays [ haskell-nixpkgs-improvements.overlays.cross-win ];
      pkgs-cross-win = null;
    in
    haskell-nixpkgs-improvements.lib.mk-haskell-tools {
      inherit system;
      vanilla-pkgs   = pkgs-haskell;
      cross-win-pkgs = pkgs-cross-win;
    };

  all-haskell-tools =
    pkgs.lib.attrsets.unionOfDisjoint haskell-tools.tools
      haskell-tools.ghc.host;
      # (pkgs.lib.attrsets.unionOfDisjoint haskell-tools.ghc.host haskell-tools.ghc.cross-win);

  dev-pkgs = import ./dev-pkgs.nix {
    inherit system;
    pkgs = pkgs-opt;
  };

  wm-sh = scripts.wm-sh;

  emacs = (dotemacs.lib.mk-emacs-config {
    inherit system;
    inherit haskell-tools;
    arch = if arch == null then null else arch.gccArch;
    pkgs = pkgs-opt;
  }).native;

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
    homeDirectory = homeDir;
    stateVersion  = "22.05";
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

      "baobab-new"          = "nohup dbus-run-session baobab >/dev/null";
    };
    sessionVariables = {
      "HIE_BIOS_CACHE_DIR"        = "/tmp/dist/hie-bios";
      "EMACS_ROOT"                = "${homeDir}/.emacs.d";
      "EMACS_WRITABLE_ROOT"       = "${homeDir}/.emacs.d";
      "CCACHE_COMPRESS"           = "1";
      "CCACHE_DIR"                = "/tmp/.ccache";
      "CCACHE_NOSTATS"            = "1";
      # So that latex will pick up .cls/.sty files from current directory
      "TEXINPUTS"                 = ".:";
      "TMPDIR"                    = "/tmp";
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
        name  = "Sergey Vinokurov";
        email = "serg.foo@gmail.com";
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
    "d /tmp/cache                    0755 sergey users - -"
    "d /tmp/cache/emacs              0755 sergey users - -"
    "d /tmp/windows-shared           0755 sergey users - -"
    "d ${homeDir}/.config            0755 -      -     - -"
    "d ${homeDir}/.local             0755 -      -     - -"
    "d ${homeDir}/.java              0755 -      -     - -"
    "d ${homeDir}/Desktop            0755 -      -     - -"

    # Forcefully symlink, removing destination if it exists.
    "L+ ${homeDir}/.emacs.d/compiled 0755 -      -     - /tmp/cache/emacs"
  ];

  dconf.settings = {
    "org/gtk/settings/file-chooser" = {
      "sort-directories-first" = true;
    };
  };

  xdg = {
    desktopEntries = {
      emacs = emacs.desktop-entry;
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
      # pkgs.autoconf
      pkgs.baobab
      # pkgs.ccache
      # pkgs.clang
      # pkgs.clang-tools
      pkgs.clinfo
      pkgs.cloc
      # pkgs.coq
      pkgs.cpu-x
      pkgs.curl
      pkgs.dmidecode
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
      #pkgs.inkscape
      pkgs.iotop
      pkgs.kdePackages.ark
      pkgs.kdePackages.filelight # Disk usage visualization tool, alternative to baobab
      pkgs.sergv-extensions.ksysguard6
      pkgs.kdePackages.okular
      pkgs.kdePackages.oxygen-icons
      pkgs.lsof
      pkgs-opt.lzip
      pkgs-opt.lzop
      pkgs-opt.mc
      pkgs.mesa-demos
      pkgs-opt.mpv
      pkgs.nix-index
      pkgs-opt.p7zip
      pkgs.pavucontrol

      # pkgs.pmutils
      pkgs.pv
      pkgs.smartmontools
      pkgs.sshfs
      pkgs.unrar
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

      tex-pkg
      wmctrl-pkg

      emacs.built-config
    ]
    ++ builtins.attrValues dev-pkgs
    ++ builtins.attrValues all-haskell-tools
    ++ builtins.attrValues my-fonts
    ++ builtins.attrValues scripts

    # Btrfs utils
    # ++
    # [ pkgs.btrfs-progs
    #   pkgs.compsize
    # ]
    ;

}

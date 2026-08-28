{ config, pkgs, pkgs-opt, lib, sergv, ... }:
{
  options.sergv.desktop = {
    dev.host-ghc-versions = lib.mkOption {
      type        = lib.types.nullOr (lib.types.listOf lib.types.str);
      example     = ''["ghc912", "ghc914", "default"]'';
      default     = null;
      description = "Names of attributes produced by haskell-nixpkgs-improvements denoting GHC versions to add to system. null means don’t filter anything out.";
    };
  };

  config =
    let
      wmctrl-pkg = pkgs.wmctrl;

      scripts = import sergv.packages.scripts {
        inherit pkgs;
        wmctrl = wmctrl-pkg;
      };

      filtered-scripts = builtins.removeAttrs scripts ["wm-sh"];

      haskell-tools =
        let
          pkgs-haskell   = pkgs-opt.appendOverlays [ sergv.inputs.haskell-nixpkgs-improvements.overlays.host ];
          # pkgs-cross-win = pkgs-opt.appendOverlays [ sergv.inputs.haskell-nixpkgs-improvements.overlays.cross-win ];
          pkgs-cross-win = null;
        in
        sergv.inputs.haskell-nixpkgs-improvements.lib.mk-haskell-tools {
          inherit (pkgs) system;
          vanilla-pkgs   = pkgs-haskell;
          cross-win-pkgs = pkgs-cross-win;
        };

      select-ghc-versions = all-versions:
        let selected = config.sergv.desktop.dev.host-ghc-versions;
        in
        if selected == null
        then all-versions
        else
          builtins.foldl'
            (acc: key: acc // { "${key}" = builtins.getAttr key all-versions; })
            {}
            selected;

      all-haskell-tools =
        pkgs.lib.attrsets.unionOfDisjoint haskell-tools.tools
          (select-ghc-versions haskell-tools.ghc.host);
      # (pkgs.lib.attrsets.unionOfDisjoint haskell-tools.ghc.host haskell-tools.ghc.cross-win);

      dev-pkgs = import ./dev-pkgs.nix {
        inherit sergv;
        pkgs = pkgs-opt;
      };

      emacs = (sergv.inputs.dotemacs.lib.mk-emacs-config {
        inherit (pkgs) system;
        inherit haskell-tools;
        arch = config.sergv.native-optimizations.gccArch;
        pkgs = pkgs-opt;
      }).native;

    in
    {
      home-manager.users."${config.sergv.user.name}" = {

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

          username      = config.sergv.user.name;
          homeDirectory = config.sergv.user.homeDirectory;
          stateVersion  = "22.05";
        };

        xdg = lib.mkMerge
          [
            (lib.optionalAttrs sergv.isLinux {
              desktopEntries = {
                emacs = emacs.desktop-entry;
              };
              # dataFile."applications/emacs.desktop".text = emacsDesktopItem;
              # dataFile."applications/i2p.desktop".text = i2pDesktopItem;
            })

            {
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
            }
          ];

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        programs.gpg = {
          enable = true;
        };

        services.gpg-agent = {
          enable           = true;
          defaultCacheTtl  = 3600000000;
          maxCacheTtl      = 3600000000;
          pinentry.package = sergv.pkgs-pristine.pinentry-qt;
        };

        dconf.settings = {
          "org/gtk/settings/file-chooser" = {
            "sort-directories-first" = true;
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
            pkgs.kdePackages.okular
            pkgs.kdePackages.oxygen-icons
            pkgs.lsof
            pkgs-opt.lzip
            pkgs-opt.lzop
            pkgs-opt.mc
            pkgs.mesa-demos
            pkgs.nix-index
            pkgs-opt.p7zip

            # pkgs.pmutils
            pkgs.pv
            pkgs.sshfs
            pkgs.unrar
            pkgs-opt.unzip
            pkgs.usbutils
            pkgs-opt.vorbis-tools
            pkgs.wget
            pkgs.xev
            pkgs-opt.zip
            # pkgs.yasm
            pkgs-opt.zstd
            # pkgs.z3

            pkgs.xd

            pkgs-opt.nix-diff

            tex-pkg

            emacs.built-config
          ]
          ++ builtins.attrValues dev-pkgs
          ++ builtins.attrValues all-haskell-tools
          ++ builtins.attrValues filtered-scripts

          # Btrfs utils
          # ++
          # [ pkgs.btrfs-progs
          #   pkgs.compsize
          # ]
          ;
      };
    };
}

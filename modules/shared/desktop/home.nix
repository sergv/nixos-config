{ config, pkgs, pkgs-opt, lib, sergv, ... }:
{
  config =
    let
      wmctrl-pkg = pkgs.wmctrl;

      scripts = import sergv.packages.scripts {
        inherit pkgs;
        wmctrl = wmctrl-pkg;
      };

      filtered-scripts = builtins.removeAttrs scripts ["wm-sh"];

      dev-pkgs = import ./dev-pkgs.nix {
        inherit sergv lib;
        pkgs = pkgs-opt;
      };

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

        xdg =
          {
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

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

        programs.gpg = {
          enable = true;
        };

        services.gpg-agent = {
          enable           = true;
          defaultCacheTtl  = 3600000000;
          maxCacheTtl      = 3600000000;
          pinentry.package =
            if sergv.isDarwin
            then pkgs.pinentry_mac
            else sergv.pkgs-pristine.pinentry-qt;
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
            # pkgs.ccache
            # pkgs.clang
            # pkgs.clang-tools
            pkgs.clinfo
            pkgs.cloc
            # pkgs.coq
            pkgs.curl
            pkgs.file
            pkgs.findutils
            pkgs-opt.graphviz
            pkgs-opt.htop
            pkgs.imagemagick
            pkgs.lsof
            pkgs-opt.lzip
            pkgs-opt.lzop
            pkgs-opt.mc
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

            pkgs-opt.nix-diff

            tex-pkg
          ]
          ++ builtins.attrValues dev-pkgs
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

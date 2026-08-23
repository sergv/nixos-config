{
  # NixOS config
  osConfig,
  # pkgs created by nixos configuration
  pkgs,
  pkgs-pristine,
  pkgs-opt,
  utils,
  ...
}:
let
  homeDir = osConfig.users.users.sergey.home;

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
      minizip
      ;
  };

  steam = pkgs.steam.override (_: {
    # # Remove non-free parts.
    # steam-unwrapped = null;
    # Add 32-bit pulseaudio for Supreme Commander.
    extraLibraries = steam-pkgs: [ steam-pkgs.libpulseaudio ];
  });

  game-run-wrapper = pkgs.writeScriptBin "game-run" ''
    #!${pkgs.bash}/bin/bash
    exec "${steam.run}/bin/steam-run" "''${@}"
  '';

  qbittorrent-pkg =
    let
      scale = "1.5";
      #scale = "1.0";
    in
    (pkgs.qbittorrent.override {
      webuiSupport = false;
      trackerSearch = false;
    }).overrideAttrs
      (old: {

        postInstall = old.postInstall + ''
          sed -i -re 's/^Exec=(.*)/Exec=env QT_SCALE_FACTOR=${scale} \1/' "$out/share/applications/org.qbittorrent.qBittorrent.desktop"
        '';
      });

  tribler-pkg =
    let
      tribler-python = pkgs.python310;
      libtorrent-rasterbar-1_2_x-upd =
        let
          version = "1.2.19";
        in
        (pkgs.libtorrent-rasterbar-1_2_x.override (old: {
          boost = old.boost.override (_: {
            enableStatic = true;
            enableShared = false;
          });
          openssl = old.openssl.override (_: {
            static = true;
          });
          python = tribler-python;
        })).overrideAttrs
          (old: {

            inherit version;

            src = pkgs.fetchgit {
              url = "https://github.com/arvidn/libtorrent.git";
              rev = "v${version}";
              sha256 = "sha256-dkjNv40/B1bbY16xtYFXOgbbOFnRSp9G2eG5/6dxfgI="; # pkgs.lib.fakeSha256;
            };

            nativeBuildInputs = old.nativeBuildInputs ++ [
              tribler-python.pkgs.setuptools
              pkgs.boost-build
              pkgs.openssl.dev
            ];

            preConfigure =
              (old.preConfigure or "")
              + "\n"
              + ''
                configureFlagsArray+=('PYTHON_INSTALL_PARAMS=--prefix=$(DESTDIR)$(prefix) --single-version-externally-managed --record=installed-files.txt')
              '';

          });
    in
    pkgs.tribler.override (old: {
      libtorrent-rasterbar-1_2_x = libtorrent-rasterbar-1_2_x-upd;
      python3 = tribler-python;
    });

  # wine-pkg = utils.use-march-optimizations arch pkgs pkgs.wineWow64Packages.stagingFull;
  wine-pkg = pkgs-opt.wineWow64Packages.stagingFull;

  winetricks-pkg =
    let
      winetricks = pkgs.winetricks;
    in
    # ‘winetricks’ relies on knowing architecture of the ‘wine’
    # executable, but on NixOS the ‘wine’ executable is a shell
    # script wrapper which breaks ‘winetricks’. This export makes
    # ‘winetricks’ learn about actual ‘wine’ executable and infer
    # its architecture properly.
    pkgs.runCommand "wrapped-winetricks"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
      # makeWrapper "${winetricks}/bin/winetricks" "$out/bin/winetricks" --set-default "WINE_BIN" "$(dirname $(readlink -f $(which wine)))/.wine"
      ''
        mkdir -p "$out/bin"
        makeWrapper "${winetricks}/bin/winetricks" "$out/bin/winetricks" --set-default "WINE_BIN" "${wine-pkg}/bin/.wine"
      ''

    # export WINE_BIN=$(dirname $(readlink -f $(which wine)))/.wine

    #patched
    ;

  strawberry-pkg = pkgs-opt.strawberry.overrideAttrs (old: {
    src = pkgs.fetchgit {
      url = "https://github.com/sergv/strawberry.git";
      rev = "fb93e0e09454dcc154c1901c4df196271fe2d549";
      sha256 = "sha256-rrjeMg/cYSbcbbBtT/VvyXysfNnikMHXRwyiPe5Hguk="; # pkgs.lib.fakeSha256;
    };

    buildInputs = builtins.filter (x: x.name != pkgs.gst_all_1.gst-plugins-rs.name) old.buildInputs;

    cmakeFlags =
      (old.cmakeFlags or [ ])
      ++ builtins.map (x: pkgs.lib.cmakeBool x false) [
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
in
{
  home = {
    keyboard = {
      layout = "us,ru";
      variant = "dvorak,";
      options = [
        "grp:shifts_toggle"
        "caps:escape"
      ];
    };
  };

  programs.bash = {
    shellAliases = {
      "youtube-dl-playlist" = "yt-dlp --write-description --add-metadata -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' --output '%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s'";
      "youtube-dl-single"   = "yt-dlp --write-description --add-metadata -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best' --output '%(title)s.%(ext)s'";
      "youtube-dl-audio"    = "yt-dlp --add-metadata -f 'bestaudio[ext=m4a]' --output '%(title)s.%(ext)s'";
    };
    sessionVariables = {
      "EMACS_SYSTEM_TYPE" = "(linux home)";
    };
  };

  programs.ssh = {
    matchBlocks = {
      "github.com" = {
        hostname     = "github.com";
        user         = "git";
        identityFile = homeDir + "/.ssh/github_sergv_id_rsa";
      };
      "gitlab.com" = {
        hostname     = "gitlab.com";
        user         = "git";
        identityFile = homeDir + "/.ssh/anon-gitlab-key";
      };
      "gitlab.haskell.org" = {
        hostname     = "gitlab.haskell.org";
        user         = "git";
        identityFile = homeDir + "/.ssh/haskell-ghc-gitlab-key";
      };
    } //
      builtins.listToAttrs
        (builtins.map
          (hostname: {
            name  = hostname;
            value = {
              inherit hostname;
              user         = "sergey";
              identityFile = homeDir + "/.ssh/macbook.key";
            };
          })
          ["macbook" "macbook-wifi" "macbook-wire"]);
  };

  xdg = {
    # Disable xdg-desktop-portal-gtk which brings gnome-settings-daemon as dependency.
    portal.extraPortals = pkgs.lib.mkForce [ pkgs.xdg-desktop-portal-kde ];

    desktopEntries = {
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
    # dataFile."applications/i2p.desktop".text = i2pDesktopItem;
  };

  programs.chromium = {
    enable = true;
    # Take from pristine so that it will be picked up from cache. Building chromium
    # is almost impossible.
    # pkgs-pristine.chromium
    # pkgs.google-chrome
    package = pkgs-pristine.ungoogled-chromium;
  };

  home.packages =
    [
      pkgs-pristine.anki
      pkgs.bridge-utils
      pkgs.fahclient
      pkgs.pavucontrol
      # for shsplit
      pkgs.shntool
      pkgs-pristine.telegram-desktop

      pkgs-opt.ffmpeg
      # pkgs-opt.ffmpeg-full
      # (pkgs-opt.ffmpeg-full.override (old: {
      #   # frei0r-plugins doesn’t build.
      #   withFrei0r    = false;
      #   withSamba     = false;
      #   withStripping = true;
      # }))

      pkgs.pavucontrol
      pkgs-opt.mpv
      pkgs-opt.vlc
      pkgs.yt-dlp

      # Take from pristine so that it will be picked up from cache. Building thunderbird
      # is almost impossible - linking consumes too much memory.
      pkgs-pristine.thunderbird
      pkgs-pristine.libreoffice

      # Music
      strawberry-pkg

      pkgs.i2p

      qbittorrent-pkg
      # tribler-pkg

      # byar

      # pkgs.vmware-workstation

      pkgs.cabextract
      wine-pkg
      winetricks-pkg

      game-run-wrapper
    ]
    ++ builtins.attrValues cuda-pkgs;
}

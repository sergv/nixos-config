{
  description = "My desktop config";

  inputs = {

    nixpkgs-20-03 = {
      url = "github:nixos/nixpkgs?ref=nixos-20.03";
    };

    nixpkgs-20-09 = {
      url = "github:nixos/nixpkgs?ref=nixos-20.09";
    };

    nixpkgs-22-11 = {
      url = "github:nixos/nixpkgs?ref=nixos-22.11";
    };

    nixpkgs-23-11 = {
      url = "github:nixos/nixpkgs?ref=nixos-23.11";
    };

    nixpkgs = {
      # url = "nixpkgs/nixos-24.11";
      # url = "nixpkgs/nixos-23.05";
      # url = "nixpkgs/nixos-unstable";
      # url = "nixpkgs/nixos-26.05";
      url = "github:nixos/nixpkgs?ref=release-26.05";
    };

    # nixpkgs-fresh-ghc = {
    #   url = "git+https://github.com/sternenseemann/nixpkgs.git?ref=ghc-9.4.4";
    # };

    home-manager = {
      # # unstable
      url = "github:nix-community/home-manager/release-26.05";
      # url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      # url = "github:nix-community/impermanence";
      url = "github:nix-community/impermanence";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    arkenfox = {
      # url = "git+https://github.com/dwarfmaster/arkenfox-nixos?ref=main";
      url = "github:dwarfmaster/arkenfox-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.pre-commit.follows = "git-hooks";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    haskellNix = {
      url = "github:input-output-hk/haskell.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
    };

    haskell-nixpkgs-improvements = {
      url = "github:sergv/haskell-nixpkgs-improvements";

      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-unstable.follows = "nixpkgs";
      inputs.haskellNix.follows = "haskellNix";
    };

    bore-scheduler-src = {
      url = "github:firelzrd/bore-scheduler";
      flake = false;
    };

    kernel-march-patches = {
      url = "github:graysky2/kernel_compiler_patch";
      flake = false;
    };

    linuk-tkg-src = {
      url = "github:Frogging-Family/linux-tkg";
      flake = false;
    };

    ksysguard6-src = {
      url = "github:sergv/ksysguard6";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotemacs = {
      url = "github:sergv/dotemacs";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.trix.follows = "trix";
      inputs.haskell-nixpkgs-improvements.follows = "haskell-nixpkgs-improvements";
    };

    # # inputs.nixpkgs.url = "github:nixos/nixpkgs";
    # inputs.hackage-server.url = "github:bgamari/hackage-server/wip/doc-builder-tls";
    # inputs.cabal.url = "github:haskell/cabal/cabal-install-v3.10.3.0";
    # inputs.cabal.flake = false;
    # inputs.hackage-security.url = "github:haskell/hackage-security/hackage-security/v0.6.2.6";
    # inputs.hackage-security.flake = false;

    trix = {
      url = "github:aanderse/trix";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    NixOS-WSL = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

  };

  outputs =
    {
      nixpkgs-20-03,
      nixpkgs-20-09,
      nixpkgs-22-11,
      nixpkgs-23-11,
      nixpkgs,
      # , nixpkgs-fresh-ghc
      home-manager,
      impermanence,
      arkenfox,
      nur,
      # , haskellNix
      haskell-nixpkgs-improvements,
      bore-scheduler-src,
      kernel-march-patches,
      linuk-tkg-src,
      ksysguard6-src,
      dotemacs,
      trix,
      NixOS-WSL,
      ...
    }:
    let
      system = "x86_64-linux";

      # In configuration.nix
      ssh-overlay = _: old: {
        openssh = old.openssh.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ patches/openssh-disable-permission-check.patch ];
          # Whether to run tests
          doCheck = false;
        });
      };

      systemd-disable-age-verification-overlay = _: old: {
        systemd = old.systemd.override {
          withUserDb = false;
          withHomed = false; # homed depends on userdb

          withAcl = false;
          withApparmor = false;
          withAudit = false;
          withTpm2Tss = false;
        };
        mariadb-server = builtins.abort "don't want mariadb";
        mariadb = builtins.abort "don't want mariadb";
        gst-plugins-rs = builtins.abort "don't want gst-plugins-rs";
        electron = builtins.abort "don't want electron";
        # gnome-settings-daemon = builtins.abort "don't want grone-settings-daemon";
        # xdg-desktop-portal-gnome = builtins.abort "don't want xdg-desktop-portal-gnome";
        # xdg-desktop-portal-gtk = builtins.abort "don't want xdg-desktop-portal-gtk";
      };

      packages-to-optimize = [
        # "cairo"
        # "harfbuzz"
        # "gtk3-x11"
        # "tree-sitter"
        #
        # "isabelle"
        #
        # "gimp"
        # "graphviz"
        # "mpv"
        # "p7zip"
        # "strawberry"
        # "vlc"
        # "zstd"

        # "qt6"
        "libxcomposite"
        "libxcursor"
        "libxcvt"
        "libxfixes"
        "libxext"
        "libxft"
        "libxrandr"
        "libxrender"
        "xorg-server"
        "xf86-input-libinput"
        "xf86-input-evdev"
      ];

      # Build some packages with -march=znver4
      zen4-march-overlay =
        new: old:
        builtins.listToAttrs (
          builtins.map (x: {
            name = x;
            value = arch.use-march-optimizations old (builtins.getAttr x old);
          }) packages-to-optimize
        )
        // {

          # kdePackages = old.kdePackages // {
          #   mkKdeDerivation = arch.use-march-optimizations old old.mkKdeDerivation;
          #   # plasma-desktop = arch.use-march-optimizations old old.kdePackages.plasma-desktop;
          #   # kwin           = arch.use-march-optimizations old old.kdePackages.kwin;
          #   # kwin-x11       = arch.use-march-optimizations old old.kdePackages.kwin-x11;
          # };

          # wineWow64Packages = old.wineWow64Packages // {
          #   stagingFull = arch.use-march-optimizations old old.wineWow64Packages.stagingFull;
          # };

          # # llvmPackages_15 = old.llvmPackages_15.extend (_: old2: {
          # #   libllvm = old2.libllvm.override (_: {
          # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
          # #     stdenv = old.clangStdenv;
          # #   });
          # #   llvm = old2.llvm.override (_: {
          # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
          # #     stdenv = old.clangStdenv;
          # #   });
          # # });
          # #
          # # # llvmPackages_16 = old.llvmPackages_16.override {
          # # #   stdenv = old.clangStdenv;
          # # # };
          # #
          # # llvmPackages_16 = old.llvmPackages_16.extend (_: old2: {
          # #   libllvm = old2.libllvm.override (_: {
          # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
          # #     stdenv = old.clangStdenv;
          # #   });
          # #   llvm = old2.llvm.override (_: {
          # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
          # #     stdenv = old.clangStdenv;
          # #   });
          # # });
          # #
          # # llvmPackages_17 = old.llvmPackages_17.extend (_: old2: {
          # #   libllvm = old2.libllvm.override (_: {
          # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
          # #     stdenv = old.clangStdenv;
          # #   });
          # #   llvm = old2.llvm.override (_: {
          # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
          # #     stdenv = old.clangStdenv;
          # #   });
          # # });

          # # libvorbis = old.libvorbis.override (_: {
          # #
          # #   # GCC 13.2 leads to segfault during testing. If we ignore tests
          # #   # then other package’s tests will segfault, libvorbis is somehow not
          # #   # functional with GCC 13.2.
          # #   stdenv = old.clangStdenv; #old.overrideCC old.stdenv old.gcc12;
          # #
          # #   # Disable -march and -mtune for a package.
          # #   # stdenv = old.stdenv.override (old2: old2 // {
          # #   #   hostPlatform   = old2.hostPlatform // {
          # #   #     gcc = {};
          # #   #   };
          # #   #   buildPlatform  = old2.buildPlatform // {
          # #   #     gcc = {};
          # #   #   };
          # #   #   targetPlatform = old2.targetPlatform // {
          # #   #     gcc = {};
          # #   #   };
          # #   # });
          # # });

          # # libvorbis = old.libvorbis.overrideAttrs (_: {
          # #   # doCheck = false;
          # # });

          # gsl = old.gsl.overrideAttrs (_: {
          #   doCheck = false;
          # });

          # tzdata = old.tzdata.overrideAttrs (_: {
          #   doCheck = false;
          # });

          # virtualbox = old.virtualbox.overrideAttrs (old2: {
          #   patches = (old2.patches or []) ++ [patches/vitrualbox-fix-bin2c-with-march.patch];
          # });

          # libreoffice = old.libreoffice.override (old2: {
          #   unwrapped = old2.unwrapped.overrideAttrs (_: {
          #     doCheck = false;
          #   });
          # });

          # python311 = old.python311.override {
          #   packageOverrides = _: old2: {
          #     pandas = old2.pandas.overrideAttrs (old-pandas-attrs: {
          #       doCheck        = false;
          #       doInstallCheck = false;
          #     });
          #   };
          # };

          # qt5 = old.qt5 // {
          #   qtwebengine = builtins.abort "Don't build qtwebengine5";
          # };

          # qt5 = old.qt5 // {
          #   qtwebengine = old.qt5.qtwebengine.override (_: {
          #     stdenv = new.clangStdenv;
          #   });
          # };

        };

      # Fixes for building packages with -march=znver4
      zen4-march-fixes-overlay = new: old: {

        # libtpms = arch.disable-march-optimizations old old.libtpms;
        libtpms = old.libtpms.overrideAttrs (_: {
          doCheck = false;
        });

        rapidjson = old.rapidjson.overrideAttrs (_: {
          doCheck = false;
        });

        # Doesn’t build either way, easier to do without until I really need this.
        # frei0r = arch.disable-march-optimizations old old.frei0r;
        # (old.frei0r.overrideAttrs (old: {
        #   version = "2.5.6";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "dyne";
        #     repo  = "frei0r";
        #     rev   = "530f7e6388c6931f20aa2ca9e4ea33a60df7aca7";
        #     hash  = "sha256-EUFNPAAdsa96mYiCoLbD7v5PweU4atCsKh345zTDGo0=";
        #   };
        # }));

        # upower = old.upower.overrideAttrs (_: {
        #   doCheck = false;
        # });

        python313 = old.python313.override {
          packageOverrides = _: old2: {
            scipy = old2.scipy.overrideAttrs (old-attrs: {
              doCheck        = false;
              doInstallCheck = false;
            });
          };
        };

      };

      # git-proxy = "http://LOGIN:PASSWORD@HOST:PORT";
      #
      # git-proxy-conf = {
      #   proxy           = git-proxy;
      #   sslCAInfo       = "path";
      #   sslCAPath       = "path";
      #   sslverify       = false;
      #   proxyAuthMethod = "basic";
      # };

      git-proxy-conf = { };

      # Make git invoked via nixpkgs’s fetchgit work behind proxy.
      improve-fetchgit-overlay = final: old: {
        # fetchgit =
        #   let
        #     # From https://stackoverflow.com/questions/58169512/call-fetchgit-without-ssl-verify
        #     fetchgit-improved = old.fetchgit // {
        #       __functor = self : args :
        #         (old.fetchgit.__functor self args).overrideAttrs (oldAttrs: {
        #           GIT_SSL_NO_VERIFY         = true;
        #           GIT_HTTP_PROXY_AUTHMETHOD = "basic";
        #           https_proxy               = git-proxy;
        #         });
        #     };
        #
        #   in fetchgit-improved;
      };

      # Mostly for chromium. Never switch to -march=native, the point is to avoid
      # prohibitively expensive builds.
      pkgs-pristine = import nixpkgs {
        inherit system;
        config = {
          # allowBroken                    = true;
          allowUnfree = true;
          # virtualbox.enableExtensionPack = true;
        };
        # # NB keep this really pristine, any overlay here invalidates
        # # cache.
        # overlays = [
        #   # ssh-overlay
        #   # improve-fetchgit-overlay
        #   # haskell-nixpkgs-improvements.overlay.enable-ghc-unit-ids
        # ];
      };

      arch = import ./arch.nix;

      common-nixpkgs-config = {
        # allowBroken                    = true;
        allowUnfree = true; # For nvidia drivers.
        # # May be needed for ghc windows cross-compiler but enabling it
        # # breaks cuda-pkgs - it starts pulling in wrong dependency
        # # that doesn’t build.
        # allowUnsupportedSystem         = true;
        # virtualbox.enableExtensionPack = true;
        #inherit (arch) replaceStdenv;
      }
        // haskell-nixpkgs-improvements.config.host;

      common-nixpkgs-overlays = [
        ssh-overlay
        systemd-disable-age-verification-overlay
        trix.overlays.default

        nur.overlays.default
        ksysguard6-src.overlays.default
        # improve-fetchgit-overlay
      ];

      # pkgs = pkgs-pristine;
      pkgs = import nixpkgs {
        inherit system;
        # inherit (arch) localSystem;
        config   = common-nixpkgs-config;
        overlays = common-nixpkgs-overlays ++ [zen4-march-overlay];
      };

      pkgs-opt = import nixpkgs {
        # inherit system;
        inherit (arch) localSystem;
        config   = common-nixpkgs-config;
        overlays = common-nixpkgs-overlays ++ [zen4-march-fixes-overlay];
      };

      home-manager-extra-args = {
        # inherit nixpkgs-fresh-ghc;
        # NixOS will provide its own pkgs.
        # inherit pkgs;
        inherit arch system;
        inherit pkgs-pristine;
        inherit arkenfox;
        inherit git-proxy-conf;
        inherit haskell-nixpkgs-improvements;
        inherit dotemacs;
        inherit pkgs-opt;
      };

      home-manager-module = {
        home-manager = {
          useGlobalPkgs    = true;
          useUserPackages  = true;
          # users.sergey     = import ./home.nix;
          extraSpecialArgs = home-manager-extra-args;
          users.sergey = {
            imports = [
              ./home/firefox.nix
              ./home.nix
            ];
          };
        };
      };
    in
    {

      # System configs
      nixosConfigurations = {
        home = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit pkgs;

          modules = [
            ./system/compressed-root.nix
            ./system/zram-swap.nix
            ./hardware-configuration.nix
            (import ./system/kernel.nix { inherit bore-scheduler-src kernel-march-patches linuk-tkg-src; })

            (import ./system/system-config-common.nix { nix-daemon-build-dir = "/builds-nix-tmp"; })
            ./system/system-config-home-desktop.nix

            (import ./system/volatile-root.nix { inherit impermanence; })

            home-manager.nixosModules.home-manager
            home-manager-module
          ];
        };

        wsl = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit pkgs;

          modules = [
            NixOS-WSL.nixosModules.wsl

            (import ./system/system-config-common.nix { nix-daemon-build-dir = "/builds-nix-tmp"; })
            ./system/system-config-wsl.nix

            home-manager.nixosModules.home-manager
            home-manager-module
          ];
        };
      };

      # # Home configs for user
      # homeManagerConfigurations = {
      #   sergey = home-manager.lib.homeManagerConfiguration {
      #     inherit pkgs;
      #     modules = [
      #
      #       (_: {
      #         nixpkgs.overlays = [
      #           nur.overlays.default
      #         ];
      #       })
      #
      #       ./home.nix
      #     ];
      #     extraSpecialArgs = home-manager-extra-args;
      #   };
      # };
    };
}

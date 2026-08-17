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

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
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
      nix-darwin,
      ...
    }:
    let

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
      march-overlay = arch: new: old:
        builtins.listToAttrs (
          builtins.map (x: {
            name  = x;
            value = utils.use-march-optimizations arch old (builtins.getAttr x old);
          }) packages-to-optimize
        )
        // {

          # kdePackages = old.kdePackages // {
          #   mkKdeDerivation = utils.use-march-optimizations arch-zen4 old old.mkKdeDerivation;
          #   # plasma-desktop = utils.use-march-optimizations arch-zen4 old old.kdePackages.plasma-desktop;
          #   # kwin           = utils.use-march-optimizations arch-zen4 old old.kdePackages.kwin;
          #   # kwin-x11       = utils.use-march-optimizations arch-zen4 old old.kdePackages.kwin-x11;
          # };

          # wineWow64Packages = old.wineWow64Packages // {
          #   stagingFull = utils.use-march-optimizations arch-zen4 old old.wineWow64Packages.stagingFull;
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

      maybe-add-march-overlay = arch: overlays: if arch == null then overlays else overlays ++ [ (march-overlay arch) ];

      # Fixes for building packages with -march=znver4
      march-fixes-overlay = new: old: {

        # libtpms = utils.disable-march-optimizations arch-zen4 old old.libtpms;
        libtpms = old.libtpms.overrideAttrs (_: {
          doCheck = false;
        });

        rapidjson = old.rapidjson.overrideAttrs (_: {
          doCheck = false;
        });

        # Doesn’t build either way, easier to do without until I really need this.
        # frei0r = utils.disable-march-optimizations arch-zen4 old old.frei0r;
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
      mk-pkgs-pristine =
        system:
        import nixpkgs {
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

      arch-zen4 = import ./arch-zen4.nix;
      utils = import ./utils.nix;

      common-nixpkgs-config =
        {
          # allowBroken                    = true;
          allowUnfree = true; # For nvidia drivers.
          # # May be needed for ghc windows cross-compiler but enabling it
          # # breaks cuda-pkgs - it starts pulling in wrong dependency
          # # that doesn’t build.
          # allowUnsupportedSystem         = true;
          # virtualbox.enableExtensionPack = true;
          #inherit (arch-zen4) replaceStdenv;
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

      # mk-pkgs = _system: pkgs-pristine;
      mk-pkgs =
        system: arch:
        import nixpkgs {
          inherit system;
          # inherit (arch) localSystem;
          config   = common-nixpkgs-config;
          overlays = maybe-add-march-overlay arch common-nixpkgs-overlays;
        };

      mk-pkgs-opt =
        arch:
        import nixpkgs {
          # inherit system;
          inherit (arch) localSystem;
          config   = common-nixpkgs-config;
          overlays = common-nixpkgs-overlays ++ [march-fixes-overlay];
        };

      home-manager-extra-args =
        { pkgs-optimised, arch, system, ... }:
        {
          # inherit nixpkgs-fresh-ghc;
          # NixOS will provide its own pkgs.
          # inherit pkgs;
          inherit system;
          pkgs-pristine = mk-pkgs-pristine system;
          inherit arkenfox;
          inherit git-proxy-conf;
          inherit haskell-nixpkgs-improvements;
          inherit dotemacs;
          inherit pkgs-optimised;
          inherit arch;
          inherit utils;
        };

      home-manager-module =
        args@{ extra-mods, system, ... }:
        {
          home-manager = {
            useGlobalPkgs    = true;
            useUserPackages  = true;
            extraSpecialArgs = home-manager-extra-args args;
            users.sergey = {
              imports =
                [
                  ./home/common.nix
                  ./isabelle/isabelle-module.nix
                ] ++
                extra-mods;
            };
          };
        };

      common-system-args = {
        flake-self = self;
      };

    in
    {

      # System configs
      nixosConfigurations = {
        "home" =
          let
            system = "x86_64-linux";
            arch   = arch-zen4;
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = common-system-args;
            pkgs        = mk-pkgs system arch;

            modules = [
              ./system/compressed-root.nix
              ./system/zram-swap.nix
              ./system/home-desktop-hardware-config.nix
              (import ./system/kernel.nix { inherit bore-scheduler-src kernel-march-patches linuk-tkg-src; })

              (import ./system/system-config-common.nix { nix-daemon-build-dir = "/builds-nix-tmp"; })
              ./system/system-config-linux-common.nix
              ./system/system-config-home-desktop.nix

              (import ./system/volatile-root.nix { inherit impermanence; })

              home-manager.nixosModules.home-manager
              (home-manager-module {
                inherit system;
                inherit arch;
                pkgs-optimised = mk-pkgs-opt arch;
                extra-mods     = [
                  ./home/firefox.nix
                  ./home/home-desktop-specific.nix
                ];
              })
            ];
          };

        "wsl" =
          let
            system = "x86_64-linux";
            arch   = null;
          in
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = common-system-args;
            pkgs        = mk-pkgs system arch;

            modules = [
              NixOS-WSL.nixosModules.wsl
              (import ./system/system-config-common.nix { nix-daemon-build-dir = "/builds-nix-tmp"; })
              ./system/system-config-linux-common.nix
              ./system/system-config-wsl.nix

              home-manager.nixosModules.home-manager
              (home-manager-module {
                inherit system arch;
                pkgs-optimised = null;
                extra-mods     = [
                  ./home/wsl-specific.nix
                ];
              })
            ];
          };
      };

      darwinConfigurations = {
        "macbook" =
          let
            system = "aarch64-darwin";
            arch   = null;
          in
          nix-darwin.lib.darwinSystem {
            inherit system;
            specialArgs = common-system-args;
            pkgs        = mk-pkgs system arch;

            modules = [
              ./system/system-config-macos.nix

              home-manager.darwinModules.home-manager
              (home-manager-module {
                inherit system arch;
                pkgs-optimised = null;
                extra-mods     = [
                  # ./home/macos-specific.nix
                ];
              })
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
      #     extraSpecialArgs = home-manager-extra-args { pkgs-optimised = pkgs-opt; };
      #   };
      # };
    };
}

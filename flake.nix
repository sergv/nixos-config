{
  description = "My desktop config";

  inputs = {

    nixpkgs-20-03 = {
      url = "nixpkgs/nixos-20.03";
    };

    nixpkgs-20-09 = {
      url = "nixpkgs/nixos-20.09";
    };

    nixpkgs-22-11 = {
      url = "nixpkgs/nixos-22.11";
    };

    nixpkgs-23-11 = {
      url = "nixpkgs/nixos-23.11";
    };

    nixpkgs-stable = {
      url = "nixpkgs/nixos-25.05";
      # # unstable
      # url = "nixpkgs/nixos-unstable";
      #url = "nixpkgs/nixos-22.05";
      #url = "/home/sergey/nix/nixpkgs";
      # url = "nixpkgs/nixos-23.05";
      # url = "nixpkgs/nixos-24.11";
    };

    nixpkgs-unstable = {
      # url = "nixpkgs/nixos-24.11";
      # url = "nixpkgs/nixos-23.05";
      # url = "nixpkgs/nixos-unstable";
      url = "nixpkgs/nixos-25.05";
    };

    # nixpkgs-fresh-ghc = {
    #   url = "git+https://github.com/sternenseemann/nixpkgs.git?ref=ghc-9.4.4";
    # };

    home-manager = {
      # # unstable
      url                    = "github:nix-community/home-manager/release-25.05";
      # url                    = "github:nix-community/home-manager/master";
      # url                    = "github:nix-community/home-manager/release-24.11";
      # url                    = "github:nix-community/home-manager/release-23.05";
      # url                    = "github:nix-community/home-manager/release-22.11";
      # Make home-manager use our version of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-compat.follows = "flake-compat";
    };

    arkenfox = {
      # url = "git+https://github.com/dwarfmaster/arkenfox-nixos?ref=main";
      url = "github:dwarfmaster/arkenfox-nixos";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-compat.follows = "flake-compat";
      inputs.pre-commit.follows = "git-hooks";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    haskellNix = {
      url = "github:input-output-hk/haskell.nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    };

  };

  outputs =
    { nixpkgs-stable
    , nixpkgs-20-03
    , nixpkgs-20-09
    , nixpkgs-22-11
    , nixpkgs-23-11
    , nixpkgs-unstable
    # , nixpkgs-fresh-ghc
    , home-manager
    , impermanence
    , arkenfox
    , nur
    , haskellNix
    , ...
    }:
    let system = "x86_64-linux";

        hutils = import haskell/utils.nix {
          pkgs = nixpkgs-unstable.legacyPackages."${system}";
        };

        # In configuration.nix
        ssh-overlay = _: old: {
          openssh = old.openssh.overrideAttrs (old: {
            patches = (old.patches or []) ++ [patches/openssh-disable-permission-check.patch];
            # Whether to run tests
            doCheck = false;
          });
        };

        # arch-native-overlay = new: old: {
        #   stdenv = old.impureUseNativeOptimizations new.stdenv;
        # };

        enable-ghc-unit-ids-overlay =
          new: old: {
            haskell = old.haskell // {
              compiler =
                builtins.mapAttrs (_: hutils.enable-unit-ids-for-newer-ghc) old.haskell.compiler // {
                  native-bignum = builtins.mapAttrs (_: hutils.enable-unit-ids-for-newer-ghc) old.haskell.compiler.native-bignum;
                };
            };
          };

        smaller-haskell-overlay = new: old: {
          haskellPackages = hutils.fixedExtend (hutils.smaller-hpkgs old.haskell.packages.native-bignum.ghc967) (_: old2: {
            # Make everything smaller at the core by altering arguments to mkDerivation.
            # This is hacky but is needed because Isabelle’s naproche dependency cannot
            # be coerced to not do e.g. profiling by standard Haskell infrastructure
            # because it’s not a Haskell package so pkgs.haskell.lib.disableLibraryProfiling
            # doesn’t work.
            mkDerivation = x: old2.mkDerivation (x // {
              doHaddock                 = false;
              enableLibraryProfiling    = false;
              enableExecutableProfiling = false;
              # enableSharedExecutables   = false;
              # enableSharedLibraries     = false;
            });
          });

          haskell = old.haskell // {
            packages = builtins.mapAttrs (_: hutils.smaller-hpkgs-no-ghc) old.haskell.packages // {
              native-bignum = builtins.mapAtrs (_: hutils.smaller-hpkgs-no-ghc) old.haskell.packages.native-bignum;
            };
          };
        };

        # Tests of these packages fail, presumable because of -march.
        disable-problematic-haskell-crypto-pkgs-checks = old: old2: {
          cryptonite              = old.haskell.lib.dontCheck old2.cryptonite;
          crypton                 = old.haskell.lib.dontCheck old2.crypton;
          # x509-validation         = old.haskell.lib.dontCheck old2.x509-validation;
          crypton-x509-validation = old.haskell.lib.dontCheck old2.crypton-x509-validation;
          tls                     = old.haskell.lib.dontCheck old2.tls;
        };

        temporarily-disable-problematic-haskell-pkgs-checks = old: old2: {
          # Fails on GHC 9.6.4, should work on others
          unicode-data = old.haskell.lib.dontCheck old2.unicode-data;
        };

        haskell-disable-checks-overlay = _: old: {
          haskellPackages = hutils.fixedExtend old.haskellPackages
            (_: old2: temporarily-disable-problematic-haskell-pkgs-checks old old2 // disable-problematic-haskell-crypto-pkgs-checks old old2);
          haskell = old.haskell // {
            packages = old.haskell.packages // {
              # Doesn’t work: overwrites changes made by ‘smaller-haskell-overlay’.
              # ghc962 = old.haskell.packages.ghc962.override {
              #   overrides = _: old2: {
              #     x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              #   };
              # };

              # ghc94 = hutils.fixedExtend old.haskell.packages.ghc94 (_: old2: {
              #   x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              # });

              # ghc947 = hutils.fixedExtend old.haskell.packages.ghc947 (_: old2: {
              #   x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              # });

              # ghc964 = hutils.fixedExtend old.haskell.packages.ghc964 (_: old2: temporarily-disable-problematic-haskell-pkgs-checks old old2 // disable-problematic-haskell-crypto-pkgs-checks old old2);
              ghc965 = hutils.fixedExtend old.haskell.packages.ghc965 (_: old2: temporarily-disable-problematic-haskell-pkgs-checks old old2 // disable-problematic-haskell-crypto-pkgs-checks old old2);
              ghc966 = hutils.fixedExtend old.haskell.packages.ghc966 (_: old2: temporarily-disable-problematic-haskell-pkgs-checks old old2 // disable-problematic-haskell-crypto-pkgs-checks old old2);
              ghc967 = hutils.fixedExtend old.haskell.packages.ghc967 (_: old2: temporarily-disable-problematic-haskell-pkgs-checks old old2 // disable-problematic-haskell-crypto-pkgs-checks old old2);
            };
          };
        };

        # Fixes for building with -march=znver3
        zen4-march-overlay = new: old: {

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

          gsl = old.gsl.overrideAttrs (_: {
            doCheck = false;
          });

          nodejs = old.nodejs.overrideAttrs (_: {
            doCheck = false;
          });

          # tzdata = old.tzdata.overrideAttrs (_: {
          #   doCheck = false;
          # });

          redis = old.redis.overrideAttrs (_: {
            doCheck = false;
          });

          virtualbox = old.virtualbox.overrideAttrs (old2: {
            patches = (old2.patches or []) ++ [patches/vitrualbox-fix-bin2c-with-march.patch];
          });

          libreoffice = old.libreoffice.override (old2: {
            unwrapped = old2.unwrapped.overrideAttrs (_: {
              doCheck = false;
            });
          });

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

          # To avoid infinite recursion
          cabal2nix-unwrapped = old.haskell.lib.justStaticExecutables
            (old.haskell.packages.native-bignum.ghc967.generateOptparseApplicativeCompletions ["cabal2nix"]
              old.haskell.packages.native-bignum.ghc967.cabal2nix);
        };

        # Remove dependency on mcfgthreads mingw library. If we keep it
        # then cross-compiling cabal will have a hard time building network
        # packge because it will try to link executables to see whether all
        # libraries are available but without properly passed mcfgthreads
        # the linking will fail.
        use-win32-thread-model-overlay = final: old: {
          threadsCross = {
            model = "win32";
            package = null;
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

        git-proxy-conf = {};

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
        pkgs-pristine = import nixpkgs-unstable {
          inherit system;
          config = {
            allowBroken                    = true;
            allowUnfree                    = true;
            # virtualbox.enableExtensionPack = true;
          };
          # NB keep this really pristine, any overlay here invalidates
          # cache.
          overlays = [
            # ssh-overlay
            # improve-fetchgit-overlay
            # enable-ghc-unit-ids-overlay
          ];
        };

        pkgs-cross-win = import nixpkgs-unstable {
          # inherit system;
          inherit (arch) localSystem;
          inherit (haskellNix) config;
          overlays = [
            haskellNix.overlay
            enable-ghc-unit-ids-overlay
            # improve-fetchgit-overlay
            use-win32-thread-model-overlay
          ];
        };

        arch = import ./arch.nix;

        # pkgs = pkgs-pristine;
        pkgs = import nixpkgs-unstable {
          inherit system;
          # inherit (arch) localSystem;
          config = {
            allowBroken                    = true;
            allowUnfree                    = true; # For nvidia drivers.
            # virtualbox.enableExtensionPack = true;
            #inherit (arch) replaceStdenv;
          };
          overlays = [
            ssh-overlay
            enable-ghc-unit-ids-overlay
            # smaller-haskell-overlay
            haskell-disable-checks-overlay
            zen4-march-overlay
            # improve-fetchgit-overlay

            # arch-native-overlay
          ];
        };

        nixpkgs-18-09 = builtins.fetchTarball {
          url    = "https://github.com/NixOS/nixpkgs/archive/a7e559a5504572008567383c3dc8e142fa7a8633.tar.gz";
          sha256 = "sha256:16j95q58kkc69lfgpjkj76gw5sx8rcxwi3civm0mlfaxxyw9gzp6";
        };

        nixpkgs-19-09 = builtins.fetchTarball {
          url    = "https://github.com/NixOS/nixpkgs/archive/75f4ba05c63be3f147bcc2f7bd4ba1f029cedcb1.tar.gz";
          sha256 = "sha256:157c64220lf825ll4c0cxsdwg7cxqdx4z559fdp7kpz0g6p8fhhr";
        };

        # nixpkgs-18-09 = builtins.fetchGit {
        #   # Descriptive name to make the store path easier to identify
        #   name = "nixos-nixos-18.09";
        #   url = "https://github.com/NixOS/nixpkgs/";
        #   # Commit hash for nixos-unstable as of 2018-09-12
        #   # git ls-remote https://github.com/nixos/nixpkgs nixos-unstable
        #   ref = "refs/heads/nixos-18.09";
        #   rev = "a7e559a5504572008567383c3dc8e142fa7a8633";
        # };
        #
        # nixpkgs-19-09 = builtins.fetchGit {
        #   name = "nixos-nixos-19.09";
        #   url = "https://github.com/NixOS/nixpkgs/";
        #   ref = "refs/heads/nixos-19.09";
        #   rev = "75f4ba05c63be3f147bcc2f7bd4ba1f029cedcb1";
        # };

        home-manager-extra-args = {
          # inherit nixpkgs-fresh-ghc system;
          inherit pkgs-pristine;
          inherit nixpkgs-stable nixpkgs-unstable system arkenfox;
          inherit pkgs-cross-win;
          inherit git-proxy-conf;
          pinned-pkgs = {
            nixpkgs-18-09 = import nixpkgs-18-09 { inherit system; };
            nixpkgs-19-09 = import nixpkgs-19-09 { inherit system; };
            nixpkgs-20-03 = import nixpkgs-20-03 { inherit system; };
            nixpkgs-20-09 = import nixpkgs-20-09 { inherit system; };
            nixpkgs-22-11 = import nixpkgs-22-11 { inherit system; };
            nixpkgs-23-11 = import nixpkgs-23-11 { inherit system; };
          };
        };

        overlay-unstable = _: _: {
          unstable  = nixpkgs-unstable.legacyPackages.x86_64-linux;
          # fresh-ghc = nixpkgs-fresh-ghc.legacyPackages.x86_64-linux;
        };

    in {

      # System configs
      nixosConfigurations = {
        home = nixpkgs-unstable.lib.nixosSystem {
          inherit system;
          inherit pkgs;

          modules = [

            ({ config, pkgs, ... }:
              {
                nixpkgs.overlays = [
                  nur.overlays.default
                  overlay-unstable
                  # Don’t uncomment, otherwise overlays will be applied one more time.
                  # ssh-overlay
                  # smaller-haskell-overlay
                  # haskell-disable-checks-overlay
                  # zen4-march-overlay

                  # arch-native-overlay
                ];
              })

            ./system.nix

            impermanence.nixosModule

            # Enable Home Manager as NixOs module
            home-manager.nixosModules.home-manager

            {
              home-manager.useGlobalPkgs    = true;
              home-manager.useUserPackages  = true;
              home-manager.users.sergey     = import ./home.nix;
              home-manager.extraSpecialArgs = home-manager-extra-args;
              # home-manager.users.sergey = {
              #   imports = [ ./home.nix ];
              # };
            }

          ];
        };
      };

      # Home configs for user
      homeManagerConfigurations = {
        sergey = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [

            (_: {
              nixpkgs.overlays = [
                nur.overlays.default
                overlay-unstable
              ];
            })

            ./home.nix
          ];
          extraSpecialArgs = home-manager-extra-args;
        };
      };
    };
}

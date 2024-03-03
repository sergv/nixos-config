{
  description = "My desktop config";

  inputs = {

    nixpkgs-stable = {
      # # unstable
      url = "nixpkgs/nixos-unstable";
      #url = "nixpkgs/nixos-22.05";
      #url = "/home/sergey/nix/nixpkgs";
      # url = "nixpkgs/nixos-23.05";
    };

    nixpkgs-20-03 = {
      url = "nixpkgs/nixos-20.03";
    };

    nixpkgs-20-09 = {
      url = "nixpkgs/nixos-20.09";
    };

    nixpkgs-23-11 = {
      url = "nixpkgs/nixos-23.11";
    };

    nixpkgs-unstable = {
      # url = "nixpkgs/nixos-23.05";
      url = "nixpkgs/nixos-unstable";
    };

    # nixpkgs-fresh-ghc = {
    #   url = "git+https://github.com/sternenseemann/nixpkgs.git?ref=ghc-9.4.4";
    # };

    home-manager = {
      # # unstable
      # url                    = "github:nix-community/home-manager/release-23.05";
      url                    = "github:nix-community/home-manager/master";
      # url                    = "github:nix-community/home-manager/release-22.11";
      # Make home-manager use our version of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    # flake-utils = {
    #   url = "github:numtide/flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

  };

  outputs =
    { nixpkgs-stable
    , nixpkgs-20-03
    , nixpkgs-20-09
    , nixpkgs-23-11
    , nixpkgs-unstable
    # , nixpkgs-fresh-ghc
    , nur
    , home-manager
    , impermanence
    , ...
    }:
    let system = "x86_64-linux";

        hutils = import haskell/utils.nix { pkgs = nixpkgs-unstable.legacyPackages."${system}"; };

        # Fix when upgrading 22.11 -> nixos-unstable circa 2023-04-11
        fcitx-overlay = _: old: {
          fcitx         = old.fcitx5;
          fcitx-engines = old.fcitx5;
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

        smaller-haskell-overlay = new: old: {
          haskellPackages                = (hutils.smaller-hpkgs old.haskellPackages).extend (_: old2: {
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
            compiler = old.haskell.compiler // {
              ghc92         = hutils.smaller-ghc old.haskell.compiler.ghc92;
              ghc928        = hutils.smaller-ghc old.haskell.compiler.ghc928;
              ghc94         = hutils.smaller-ghc old.haskell.compiler.ghc94;
              ghc947        = hutils.smaller-ghc old.haskell.compiler.ghc947;
              ghc948        = hutils.smaller-ghc old.haskell.compiler.ghc948;
              ghc96         = hutils.smaller-ghc old.haskell.compiler.ghc96;
              ghc963        = hutils.smaller-ghc old.haskell.compiler.ghc963;
              ghc964        = hutils.smaller-ghc old.haskell.compiler.ghc964;
              ghc98         = hutils.smaller-ghc old.haskell.compiler.ghc98;
              ghc981        = hutils.smaller-ghc old.haskell.compiler.ghc981;
            };

            packages = old.haskell.packages // {
              ghc92         = hutils.smaller-hpkgs old.haskell.packages.ghc92;
              ghc928        = hutils.smaller-hpkgs old.haskell.packages.ghc928;
              ghc94         = hutils.smaller-hpkgs old.haskell.packages.ghc94;
              ghc947        = hutils.smaller-hpkgs old.haskell.packages.ghc947;
              ghc948        = hutils.smaller-hpkgs old.haskell.packages.ghc948;
              ghc96         = hutils.smaller-hpkgs old.haskell.packages.ghc96;
              ghc963        = hutils.smaller-hpkgs old.haskell.packages.ghc963;
              ghc964        = hutils.smaller-hpkgs old.haskell.packages.ghc964;
              ghc98         = hutils.smaller-hpkgs old.haskell.packages.ghc98;
              ghc981        = hutils.smaller-hpkgs old.haskell.packages.ghc981;
            };
          };
        };

        haskell-disable-checks-overlay = _: old: {
          haskellPackages = old.haskellPackages.extend (_: old2: {
            cryptonite              = old.haskell.lib.dontCheck old2.cryptonite;
            crypton                 = old.haskell.lib.dontCheck old2.crypton;
            # x509-validation         = old.haskell.lib.dontCheck old2.x509-validation;
            crypton-x509-validation = old.haskell.lib.dontCheck old2.crypton-x509-validation;
            tls                     = old.haskell.lib.dontCheck old2.tls;
          });
          haskell = old.haskell // {
            packages = old.haskell.packages // {
              # Doesn’t work: overwrites changes made by ‘smaller-haskell-overlay’.
              # ghc962 = old.haskell.packages.ghc962.override {
              #   overrides = _: old2: {
              #     x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              #   };
              # };

              # ghc94 = old.haskell.packages.ghc94.extend (_: old2: {
              #   x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              # });

              # ghc947 = old.haskell.packages.ghc947.extend (_: old2: {
              #   x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              # });
              #
              # ghc964 = old.haskell.packages.ghc964.extend (_: old2: {
              #   x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              # });
            };
          };
        };


        # Fixes for building with -march=znver3
        zen4-march-overlay = _: old: {

          libvorbis = old.libvorbis.override (_: {

            # GCC 13.2 leads to segfault during testing. If we ignore tests
            # then other package’s tests will segfault, libvorbis is somehow not
            # functional with GCC 13.2.
            stdenv = old.clangStdenv; #old.overrideCC old.stdenv old.gcc12;

            # Disable -march and -mtune for a package.
            # stdenv = old.stdenv.override (old2: old2 // {
            #   hostPlatform   = old2.hostPlatform // {
            #     gcc = {};
            #   };
            #   buildPlatform  = old2.buildPlatform // {
            #     gcc = {};
            #   };
            #   targetPlatform = old2.targetPlatform // {
            #     gcc = {};
            #   };
            # });
          });

          # libvorbis = old.libvorbis.overrideAttrs (_: {
          #   # doCheck = false;
          # });

          gsl = old.gsl.overrideAttrs (_: {
            doCheck = false;
          });

          tzdata = old.tzdata.overrideAttrs (_: {
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

          python311 = old.python311.override {
            packageOverrides = _: old2: {
              pandas = old2.pandas.overrideAttrs (old-pandas-attrs: {
                doCheck        = false;
                doInstallCheck = false;
              });
            };
          };

          # To avoid infinite recursion
          cabal2nix-unwrapped = old.haskell.lib.justStaticExecutables
            (old.haskell.lib.generateOptparseApplicativeCompletion "cabal2nix"
              old.haskell.packages.ghc964.cabal2nix);
        };

        pkgs-pristine = import nixpkgs-unstable {
          inherit system;
          config = {
            allowBroken                    = true;
            allowUnfree                    = true;
            # virtualbox.enableExtensionPack = true;
          };
          overlays = [
            fcitx-overlay
            ssh-overlay
          ];
        };

        arch = import ./arch.nix;

        # # Packages withou -march override for when
        # pkgs-default = import nixpkgs-unstable {
        #   # inherit system;
        #   inherit (arch) localSystem;
        #   config = {
        #     allowBroken                    = true;
        #     allowUnfree                    = true;
        #     # virtualbox.enableExtensionPack = true;
        #   };
        #   overlays = [
        #     fcitx-overlay
        #     ssh-overlay
        #     smaller-haskell-overlay
        #     haskell-disable-checks-overlay
        #     zen4-march-overlay
        #
        #     # arch-native-overlay
        #   ];
        # };

        pkgs = import nixpkgs-unstable {
          # inherit system;
          inherit (arch) localSystem;
          config = {
            allowBroken                    = true;
            allowUnfree                    = true;
            # virtualbox.enableExtensionPack = true;
          };
          overlays = [
            fcitx-overlay
            ssh-overlay
            smaller-haskell-overlay
            haskell-disable-checks-overlay
            zen4-march-overlay

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
          inherit nixpkgs-stable nixpkgs-unstable system;
          pinned-pkgs = {
            nixpkgs-18-09 = import nixpkgs-18-09 { inherit system; };
            nixpkgs-19-09 = import nixpkgs-19-09 { inherit system; };
            nixpkgs-20-03 = import nixpkgs-20-03 { inherit system; };
            nixpkgs-20-09 = import nixpkgs-20-09 { inherit system; };
            nixpkgs-23-11 = import nixpkgs-23-11 { inherit system; };
          };
        };

    in {

      # System configs
      nixosConfigurations = {
        home = nixpkgs-unstable.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, ... }:
              let
                overlay-unstable = _: _: {
                  unstable  = nixpkgs-unstable.legacyPackages.x86_64-linux;
                  # fresh-ghc = nixpkgs-fresh-ghc.legacyPackages.x86_64-linux;
                };
              in {
                nixpkgs.overlays = [
                  nur.overlay
                  overlay-unstable
                  fcitx-overlay
                  ssh-overlay
                  smaller-haskell-overlay
                  haskell-disable-checks-overlay
                  zen4-march-overlay
                  # arch-native-overlay
                ];
	            })

            ./system.nix

            impermanence.nixosModule

            # Enable Home Manager as NixOs module
            home-manager.nixosModules.home-manager {
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
          inherit pkgs pkgs-pristine;
          modules = [
            ./home.nix
          ];
          extraSpecialArgs = home-manager-extra-args;
        };
      };
    };
}

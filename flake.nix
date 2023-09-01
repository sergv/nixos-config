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

    # nur = {
    #   url = "github:nix-community/NUR";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    #
    # flake-utils = {
    #   url = "github:numtide/flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

  };

  outputs =
    { nixpkgs-stable
    , nixpkgs-20-03
    , nixpkgs-20-09
    , nixpkgs-unstable
    # , nixpkgs-fresh-ghc
    , home-manager
    , impermanence
    , ...
    }:
    let system = "x86_64-linux";

        hutils = import haskell/utils.nix { pkgs = nixpkgs-unstable.legacyPackages."${system}"; };

        # Fix when upgrading 22.11 -> nixos-unstable circa 2023-04-11
        fcitx-overlay = _: _: {
          fcitx         = pkgs.fcitx5;
          fcitx-engines = pkgs.fcitx5;
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
              ghc945        = hutils.smaller-ghc old.haskell.compiler.ghc945;
              ghc946        = hutils.smaller-ghc old.haskell.compiler.ghc946;
              ghc96         = hutils.smaller-ghc old.haskell.compiler.ghc96;
              ghc962        = hutils.smaller-ghc old.haskell.compiler.ghc962;
            };

            packages = old.haskell.packages // {
              ghc92         = hutils.smaller-hpkgs old.haskell.packages.ghc92;
              ghc928        = hutils.smaller-hpkgs old.haskell.packages.ghc928;
              ghc94         = hutils.smaller-hpkgs old.haskell.packages.ghc94;
              ghc945        = hutils.smaller-hpkgs old.haskell.packages.ghc945;
              ghc946        = hutils.smaller-hpkgs old.haskell.packages.ghc946;
              ghc96         = hutils.smaller-hpkgs old.haskell.packages.ghc96;
              ghc962        = hutils.smaller-hpkgs old.haskell.packages.ghc962;
            };
          };
        };

        haskell-disable-checks-overlay = _: old: {
          haskellPackages = old.haskellPackages.extend (_: old2: {
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

              ghc94 = old.haskell.packages.ghc94.extend (_: old2: {
                x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              });

              ghc946 = old.haskell.packages.ghc946.extend (_: old2: {
                x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              });

              ghc962 = old.haskell.packages.ghc962.extend (_: old2: {
                x509-validation = old.haskell.lib.dontCheck old2.x509-validation;
              });
            };
          };
        };


        # Fixes for building with -march=znver3
        zen3-march-overlay = _: old: {

          libreoffice = old.libreoffice.override (old2: {
            unwrapped = old2.unwrapped.overrideAttrs (_: {
              doCheck = false;
            });
          });

          python310 = old.python310.override {
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
              old.haskell.packages.ghc962.cabal2nix);

          openexr_3 =
            if old.openexr_3.version == "3.1.10"
            then
              old.openexr_3.overrideAttrs (_: {
                version = "3.1.11";
                src = pkgs.fetchFromGitHub {
                  owner = "AcademySoftwareFoundation";
                  repo = "openexr";
                  rev = "v3.1.11";
                  sha256 = "sha256-xW/BmMtEYHiLk8kLZFXYE809jL/uAnCzkINugqJ8Iig="; #pkgs.lib.fakeSha256;
                };
              })
            else
              builtins.abort "Override of ‘openxr’ is useless now";
        };

        pkgs = import nixpkgs-unstable {
          inherit system;
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
            zen3-march-overlay

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
          inherit nixpkgs-stable nixpkgs-unstable system;
          pinned-pkgs = {
            nixpkgs-18-09 = import nixpkgs-18-09 { inherit system; };
            nixpkgs-19-09 = import nixpkgs-19-09 { inherit system; };
            nixpkgs-20-03 = import nixpkgs-20-03 { inherit system; };
            nixpkgs-20-09 = import nixpkgs-20-09 { inherit system; };
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
                  overlay-unstable
                  fcitx-overlay
                  ssh-overlay
                  smaller-haskell-overlay
                  haskell-disable-checks-overlay
                  zen3-march-overlay
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
          inherit pkgs;
          modules = [
            ./home.nix
          ];
          extraSpecialArgs = home-manager-extra-args;
        };
      };
    };
}

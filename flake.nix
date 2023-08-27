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

        # Fix when upgrading 22.11 -> nixos-unstable circa 2023-04-11
        fcitx-overlay = _: _: {
          fcitx         = pkgs.fcitx5;
          fcitx-engines = pkgs.fcitx5;
        };

        # In configuration.nix
        ssh-overlay = _: prev: {
          openssh = prev.openssh.overrideAttrs (old: {
            patches = (old.patches or []) ++ [patches/openssh-disable-permission-check.patch];
            # Whether to run tests
            doCheck = false;
          });
        };

        arch-native-overrlay = self: super: {
          stdenv = super.impureUseNativeOptimizations super.stdenv;
        };

        pkgs = import nixpkgs-unstable {
          inherit system;
          config = {
            allowBroken                    = true;
            allowUnfree                    = true;
            virtualbox.enableExtensionPack = true;
          };
          overlays = [
            fcitx-overlay
            ssh-overlay
            # arch-native-overrlay
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
                  # arch-native-overrlay
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

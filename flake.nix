{
  description = "My desktop config";

  inputs = {

    nixpkgs = {
      # # unstable
      # url = "nixpkgs/nixos-unstable";
      #url = "nixpkgs/nixos-22.05";
      #url = "/home/sergey/nix/nixpkgs";
      url = "nixpkgs/nixos-22.11";
    };

    nixpkgs-20-03 = {
      url = "nixpkgs/nixos-20.03";
    };

    nixpkgs-20-09 = {
      url = "nixpkgs/nixos-20.09";
    };

    nixpkgs-unstable = {
      url = "nixpkgs/nixos-unstable";
    };

    # nixpkgs-fresh-ghc = {
    #   url = "git+https://github.com/sternenseemann/nixpkgs.git?ref=ghc-9.4.4";
    # };

    home-manager = {
      # # unstable
      # url                    = "github:nix-community/home-manager/master";
      url                    = "github:nix-community/home-manager/release-22.11";
      # Make home-manager use our version of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
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
    { nixpkgs
    , nixpkgs-20-03
    , nixpkgs-20-09
    , nixpkgs-unstable
    # , nixpkgs-fresh-ghc
    , home-manager
    , impermanence
    , ...
    }:
    let system = "x86_64-linux";

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree                    = true;
            virtualbox.enableExtensionPack = true;
          };
        };

        nixpkgs-18-09 = builtins.fetchGit {
          # Descriptive name to make the store path easier to identify
          name = "nixos-nixos-18.09";
          url = "https://github.com/NixOS/nixpkgs/";
          # Commit hash for nixos-unstable as of 2018-09-12
          # git ls-remote https://github.com/nixos/nixpkgs nixos-unstable
          ref = "refs/heads/nixos-18.09";
          rev = "a7e559a5504572008567383c3dc8e142fa7a8633";
        };

        nixpkgs-19-09 = builtins.fetchGit {
          name = "nixos-nixos-19.09";
          url = "https://github.com/NixOS/nixpkgs/";
          ref = "refs/heads/nixos-19.09";
          rev = "75f4ba05c63be3f147bcc2f7bd4ba1f029cedcb1";
        };

    in {

      # System configs
      nixosConfigurations = {
        home = nixpkgs.lib.nixosSystem {
          inherit system;
          # Main desktop
          modules = [
            ({ config, pkgs, ... }:
              let
                overlay-unstable = final: prev: {
                  unstable  = nixpkgs-unstable.legacyPackages.x86_64-linux;
                  # fresh-ghc = nixpkgs-fresh-ghc.legacyPackages.x86_64-linux;
                };
              in
	              {
                 nixpkgs.overlays = [ overlay-unstable ];
                 # environment.systemPackages = with pkgs; [
	                #  unstable.qutebrowser
	               # ];
	             })

            ./system.nix

            impermanence.nixosModule

            # # Enable Home Manager as NixOs module
            # home-manager.nixosModules.home-manager {
            #   home-manager.useGlobalPkgs = true;
            #   home-manager.useUserPackages = true;
            #   home-manager.users.sergey = import ./home.nix;
            #   # home-manager.users.sergey = {
            #   #   imports = [ ./home.nix ];
            #   # };
            # }
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
          extraSpecialArgs = {
            # inherit nixpkgs-fresh-ghc system;
            inherit nixpkgs-unstable system;
            pinned-pkgs = {
              nixpkgs-18-09 = import nixpkgs-18-09 { inherit system; };
              nixpkgs-19-09 = import nixpkgs-19-09 { inherit system; };
              nixpkgs-20-03 = import nixpkgs-20-03 { inherit system; };
              nixpkgs-20-09 = import nixpkgs-20-09 { inherit system; };
            };
          };
        };
      };
    };
}

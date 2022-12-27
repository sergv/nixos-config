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

    nixpkgs-unstable = {
      url = "nixpkgs/nixos-unstable";
    };

    nixpkgs-fresh-ghc = {
      url = "git+https://github.com/sternenseemann/nixpkgs.git?ref=ghc-9.4.4";
    };

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

  outputs = { nixpkgs, nixpkgs-unstable, nixpkgs-fresh-ghc, home-manager, impermanence, ... }:
    let system = "x86_64-linux";

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree                    = true;
            virtualbox.enableExtensionPack = true;
          };
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
                  fresh-ghc = nixpkgs-fresh-ghc.legacyPackages.x86_64-linux;
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
            inherit nixpkgs-fresh-ghc system;
          };
        };
      };
    };
}

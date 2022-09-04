{
  description = "My desktop config";

  inputs = {

    nixpkgs = {
      # # unstable
      # url = "nixpkgs/nixos-unstable";
      #url = "nixpkgs/nixos-22.05";
      url = "/home/sergey/nix/nixpkgs";
    };

    nixpkgs-unstable = {
      url = "nixpkgs/nixos-unstable";
    };

    home-manager = {
      # # unstable
      # url                    = "github:nix-community/home-manager/master";
      url                    = "github:nix-community/home-manager/release-22.05";
      # Make home-manager use our version of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url                         = "github:nix-community/impermanence";
      inputs.nixpkgs.follows      = "nixpkgs";
      inputs.home-manager.follows = "nixpkgs";
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

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, impermanence, ... }:
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
                  unstable = nixpkgs-unstable.legacyPackages.x86_64-linux;
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
            #  home-manager.useGlobalPkgs = true;
            #  home-manager.useUserPackages = true;
            #  home-manager.users.sergey = import ./home.nix;
            #  # home-manager.users.sergey = {
            #  #   imports = [ ./home.nix ];
            #  # };
            # }
          ];
        };
      };

      # Home configs for user
      homeManagerConfigurations = {
        sergey = home-manager.lib.homeManagerConfiguration {
          inherit system pkgs;
          username      = "sergey";
          homeDirectory = "/home/sergey";
          # stateVersion  = "22.05";
          configuration = {
            imports = [ ./home.nix ];
          };
        };
      };
    };
}

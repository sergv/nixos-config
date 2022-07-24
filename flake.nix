{
  description = "My desktop config";

  inputs = {

    nixpkgs = {
      # # unstable
      # url = "nixpkgs/nixos-unstable";
      url = "nixpkgs/nixos-22.05";
    };

    home-manager = {
      # # unstable
      # url = "github:nix-community/home-manager/master";
      url = "github:nix-community/home-manager/release-22.05";
      # Make home-manager use our version of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = { nixpkgs, home-manager, ... }:
    let system = "x86_64-linux";

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree                    = true;
            virtualbox.enableExtensionPack = true;
          };
        };

        lib = nixpkgs.lib;

    in {

      # System configs
      nixosConfigurations = {
        home = lib.nixosSystem {
          inherit system;
          # Main desktop
          modules = [
            ./system.nix

            # home-manager.nixosModules.home-manager {
            #   home-manager.useGlobalPkgs = true;
            #   home-manager.useUserPkgs = true;
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

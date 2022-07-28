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

  outputs = { nixpkgs, home-manager, impermanence, ... }:
    let system = "x86_64-linux";

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree                    = true;
            virtualbox.enableExtensionPack = true;
          };
        };

        # impermanence-config =
        #   impermanence.nixosModule {
        #     environment.persistence."/permanent" = {
        #       directories = [
        #         "/etc/NetworkManager/system-connections"
        #       ];
        #       files = [
        #         "/etc/machine-id"
        #         "/etc/ssh/ssh_host_rsa_key"
        #         "/etc/ssh/ssh_host_rsa_key.pub"
        #         "/etc/ssh/ssh_host_ed25519_key"
        #         "/etc/ssh/ssh_host_ed25519_key.pub"
        #       ];
        #     };
        #   };

    in {

      # System configs
      nixosConfigurations = {
        home = nixpkgs.lib.nixosSystem {
          inherit system;
          # Main desktop
          modules = [
            ./system.nix

            impermanence.nixosModule

            # impermanence-config

            #home-manager.nixosModules.home-manager {
            #  home-manager.useGlobalPkgs = true;
            #  home-manager.useUserPackages = true;
            #  home-manager.users.sergey = import ./home.nix;
            #  # home-manager.users.sergey = {
            #  #   imports = [ ./home.nix ];
            #  # };
            #}
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

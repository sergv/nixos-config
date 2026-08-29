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
    inputs@{
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
          #   # haskell-nixpkgs-improvements.overlay.enable-ghc-unit-ids
          # ];
        };

      arch-zen4 = import ./arch-zen4.nix;
      utils = import ./utils.nix;

      common-nixpkgs-config =
        {
          allowUnfree = true;
          # allowBroken = true;
          warnUndeclaredOptions = true;

          # # May be needed for ghc windows cross-compiler but enabling it
          # # breaks cuda-pkgs - it starts pulling in wrong dependency
          # # that doesn’t build.
          # allowUnsupportedSystem         = true;
          # virtualbox.enableExtensionPack = true;
          #inherit (arch-zen4) replaceStdenv;

          #
          # hashedMirrors = [ "mirror" ];
          #
          # rewriteURL = url: "new-url";
        }
        // haskell-nixpkgs-improvements.config.host;

      # Useful for proxies on WSL:
      fetchgit-basic-proxy-config =
        system:
        {
          gitConfigFile =
            nixpkgs.legacyPackages."${system}".writeText
              "git-basic-proxy-config"
              ''
                [http]
                  proxyAuthMethod = "basic"
                  sslverify = false
              '';
        };

      common-nixpkgs-overlays = builtins.attrValues (import ./overlays) ++ [
        trix.overlays.default
        nur.overlays.default
      ];

      # mk-pkgs = _system: pkgs-pristine;
      mk-pkgs =
        system: extra-config:
        import nixpkgs {
          inherit system;
          # inherit (arch) localSystem;
          config   = common-nixpkgs-config // extra-config;
          overlays = common-nixpkgs-overlays;
        };

      icons    = import ./icons;
      packages = import ./packages;

      common-user-config = _: {
        sergv.programs.git.enable           = true;
        sergv.programs.isabelle.enable      = true;
        sergv.desktop.dev.host-ghc-versions = ["default" "ghc912" "ghc910"];
      };

      common-system-args = system: isLinux: {
        sergv = {
          inherit utils inputs icons packages;
          flake-self    = self;
          isLinux       = isLinux;
          isDarwin      = !isLinux;
          hostPlatform  = if isLinux then "x86_64-linux" else "aarch64-darwin";
          pkgs-pristine = mk-pkgs-pristine system;
        };
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
            specialArgs = common-system-args system true;
            pkgs        = mk-pkgs system {};

            modules = [
              ./modules/shared
              ./modules/linux
              ./hosts/home

              common-user-config

              (_: {
                config = {
                  sergv.system.nix-daemon-build-dir          = "/builds-nix-tmp";

                  sergv.system.compressed-root.enable        = true;
                  sergv.system.zram-swap.enable              = true;

                  sergv.system.kde.enable                    = true;
                  sergv.programs.ksysguard.enable            = true;

                  sergv.system.nvidia.enable                 = true;
                  sergv.system.optimized-linux-kernel.enable = true;
                  sergv.persistence.enable                   = true;

                  sergv.programs.firefox.enable              = true;
                  sergv.programs.no-internet.enable          = true;

                  sergv.desktop.keybindings.enable           = true;

                  sergv.i2p.enable                           = true;
                  sergv.tor.enable                           = true;
                  sergv.tor.nickname                         = builtins.warn ("Tor nickname not set in " + __curPos.file) "todo";
                  sergv.tor.email                            = builtins.warn ("Tor email not set in " + __curPos.file) "todo@example.com";

                  sergv.native-optimizations = {
                    enable                        = true;
                    gccArch                       = "znver4";
                    gccTune                       = "znver4";
                    packages-to-optimise-globally =
                      [
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
                  };
                };
              })

              home-manager.nixosModules.home-manager
            ];
          };

        "wsl" =
          let
            system = "x86_64-linux";
            arch   = null;
          in
          nixpkgs.lib.nixosSystem {
            specialArgs = common-system-args system true;
            pkgs        = mk-pkgs system (fetchgit-basic-proxy-config system);

            modules = [
              ./modules/shared
              ./modules/linux
              ./hosts/wsl

              (_: {
                config = {
                  sergv.system.nix-daemon-build-dir = "/builds-nix-tmp";
                  sergv.persistence.enable          = false;
                  sergv.programs.ksysguard.enable   = true;
                  sergv.programs.no-internet.enable = true;

                  sergv.desktop.keybindings.enable  = false;

                  sergv.programs.git.enable         = true;
                  sergv.user.gpgKey                 = null;

                  # sergv.user.name                   = builtins.warn ("WSL user name not set in " + __curPos.file) "todo";
                  sergv.user.fullName               = builtins.warn ("WSL full user name not set in " + __curPos.file) "todo";
                  sergv.user.email                  = builtins.warn ("WSL user email not set in " + __curPos.file) "todo@example.com";

                  # {
                  #   proxy           = "http://LOGIN:PASSWORD@HOST:PORT";
                  #   sslverify       = false;
                  #   proxyAuthMethod = "basic";
                  # };
                  # will be set automatically
                  #   sslCAInfo       = "path";
                  #   sslCAPath       = "path";
                  sergv.programs.git.proxy          = builtins.warn ("WSL git proxy not set in " + __curPos.file) null;

                  networking.proxy.default          = builtins.warn ("WSL proxy not set in " + __curPos.file) null;

                  sergv.wsl.certificate-file        = builtins.warn ("WSL certificate file not set in " + __curPos.file) null;
                };
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
            specialArgs = common-system-args system false;
            pkgs        = mk-pkgs system {};

            modules = [
              ./modules/shared
              ./modules/darwin
              ./hosts/macbook

              common-user-config
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
      #     extraSpecialArgs = home-manager-extra-args;
      #   };
      # };
    };
}

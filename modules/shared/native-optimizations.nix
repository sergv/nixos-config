{ lib, config, options, pkgs, sergv, ... }:
let
  cfg = config.sergv.native-optimizations;
in
{
  options.sergv.native-optimizations = {
    enable = lib.mkEnableOption "Pass -march=XXX";

    packages-to-optimise-globally = lib.mkOption {
      type        = lib.types.listOf lib.types.str;
      # znver4, skylake
      example     = lib.literalExpression ''["libxcvt" "xorg-server"]'';
      default     = [];
      description = "Toplevel nixpkgs attributes denoting packages to optimize with architecture specified in config.sergv.gccArch";
    };

    gccArch = lib.mkOption {
      type        = lib.types.nullOr lib.types.str;
      # znver4, skylake
      example     = "znver4";
      description = "What to pass to -march";
    };

    gccTune = lib.mkOption {
      type        = lib.types.nullOr lib.types.str;
      example     = "znver4";
      description = "What to pass to -mtune";
    };
  };

  config =
    let
      pkgs-opt =
        if cfg.enable
        then
          assert lib.assertMsg (cfg.gccArch != null)
            "sergv.native-optimizations.gccArch must be set when sergv.native-optimizations is true";
          assert lib.assertMsg (cfg.gccTune != null)
            "sergv.native-optimizations.gccTune must be set when sergv.native-optimizations is true";
          import pkgs.path {
            localSystem = {
              inherit (pkgs) system;
              gcc = {
                arch = cfg.gccArch;
                tune = cfg.gccTune;
              };
            };
            inherit (pkgs) config;
            overlays = pkgs.overlays ++ [ (import ../../overlays/march-fixes.nix) ];
          }
        else
          pkgs;
    in
    {
      _module.args = {
        inherit pkgs-opt;
      };

      nixpkgs.overlays =
        if cfg.gccArch != null && cfg.packages-to-optimise-globally != []
        then
          let
            global-march-overlay = _new-pkgs: old-pkgs:
              builtins.listToAttrs (
                builtins.map (pkg-name: {
                  name  = pkg-name;
                  value = sergv.utils.use-march-optimizations
                    cfg.gccArch
                    old-pkgs
                    (builtins.getAttr pkg-name old-pkgs);
                }) cfg.packages-to-optimise-globally
              )
              # // {
              #
              #   # kdePackages = old.kdePackages // {
              #   #   mkKdeDerivation = utils.use-march-optimizations arch-zen4 old old.mkKdeDerivation;
              #   #   # plasma-desktop = utils.use-march-optimizations arch-zen4 old old.kdePackages.plasma-desktop;
              #   #   # kwin           = utils.use-march-optimizations arch-zen4 old old.kdePackages.kwin;
              #   #   # kwin-x11       = utils.use-march-optimizations arch-zen4 old old.kdePackages.kwin-x11;
              #   # };
              #
              #   # wineWow64Packages = old.wineWow64Packages // {
              #   #   stagingFull = utils.use-march-optimizations arch-zen4 old old.wineWow64Packages.stagingFull;
              #   # };
              #
              #   # # llvmPackages_15 = old.llvmPackages_15.extend (_: old2: {
              #   # #   libllvm = old2.libllvm.override (_: {
              #   # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
              #   # #     stdenv = old.clangStdenv;
              #   # #   });
              #   # #   llvm = old2.llvm.override (_: {
              #   # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
              #   # #     stdenv = old.clangStdenv;
              #   # #   });
              #   # # });
              #   # #
              #   # # # llvmPackages_16 = old.llvmPackages_16.override {
              #   # # #   stdenv = old.clangStdenv;
              #   # # # };
              #   # #
              #   # # llvmPackages_16 = old.llvmPackages_16.extend (_: old2: {
              #   # #   libllvm = old2.libllvm.override (_: {
              #   # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
              #   # #     stdenv = old.clangStdenv;
              #   # #   });
              #   # #   llvm = old2.llvm.override (_: {
              #   # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
              #   # #     stdenv = old.clangStdenv;
              #   # #   });
              #   # # });
              #   # #
              #   # # llvmPackages_17 = old.llvmPackages_17.extend (_: old2: {
              #   # #   libllvm = old2.libllvm.override (_: {
              #   # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
              #   # #     stdenv = old.clangStdenv;
              #   # #   });
              #   # #   llvm = old2.llvm.override (_: {
              #   # #     # Cannot be built with gcc 13.2 because the compiler segfaults.
              #   # #     stdenv = old.clangStdenv;
              #   # #   });
              #   # # });
              #
              #   # # libvorbis = old.libvorbis.override (_: {
              #   # #
              #   # #   # GCC 13.2 leads to segfault during testing. If we ignore tests
              #   # #   # then other package’s tests will segfault, libvorbis is somehow not
              #   # #   # functional with GCC 13.2.
              #   # #   stdenv = old.clangStdenv; #old.overrideCC old.stdenv old.gcc12;
              #   # #
              #   # #   # Disable -march and -mtune for a package.
              #   # #   # stdenv = old.stdenv.override (old2: old2 // {
              #   # #   #   hostPlatform   = old2.hostPlatform // {
              #   # #   #     gcc = {};
              #   # #   #   };
              #   # #   #   buildPlatform  = old2.buildPlatform // {
              #   # #   #     gcc = {};
              #   # #   #   };
              #   # #   #   targetPlatform = old2.targetPlatform // {
              #   # #   #     gcc = {};
              #   # #   #   };
              #   # #   # });
              #   # # });
              #
              #   # # libvorbis = old.libvorbis.overrideAttrs (_: {
              #   # #   # doCheck = false;
              #   # # });
              #
              #   # gsl = old.gsl.overrideAttrs (_: {
              #   #   doCheck = false;
              #   # });
              #
              #   # tzdata = old.tzdata.overrideAttrs (_: {
              #   #   doCheck = false;
              #   # });
              #
              #   # virtualbox = old.virtualbox.overrideAttrs (old2: {
              #   #   patches = (old2.patches or []) ++ [patches/vitrualbox-fix-bin2c-with-march.patch];
              #   # });
              #
              #   # libreoffice = old.libreoffice.override (old2: {
              #   #   unwrapped = old2.unwrapped.overrideAttrs (_: {
              #   #     doCheck = false;
              #   #   });
              #   # });
              #
              #   # python311 = old.python311.override {
              #   #   packageOverrides = _: old2: {
              #   #     pandas = old2.pandas.overrideAttrs (old-pandas-attrs: {
              #   #       doCheck        = false;
              #   #       doInstallCheck = false;
              #   #     });
              #   #   };
              #   # };
              #
              #   # qt5 = old.qt5 // {
              #   #   qtwebengine = builtins.abort "Don't build qtwebengine5";
              #   # };
              #
              #   # qt5 = old.qt5 // {
              #   #   qtwebengine = old.qt5.qtwebengine.override (_: {
              #   #     stdenv = new-pkgs.clangStdenv;
              #   #   });
              #   # };
              #
              # }
              ;
          in
          [ global-march-overlay ]
        else
          [];

      home-manager.extraSpecialArgs = { inherit pkgs-opt;  };
    };
}

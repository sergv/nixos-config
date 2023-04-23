args @
  { pinned-pkgs
  # , nixpkgs-stable
  , nixpkgs-unstable
  , system
  # , pkgs
  , ...
  }:
let pkgs = nixpkgs-unstable.legacyPackages."${system}";
    t    = pkgs.lib.trivial;
    hlib = pkgs.haskell.lib;

    # hpkgs = pkgs.haskell.packages.ghc924;

    cabal-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "cabal";
      rev    = "121f55e792222d71ad78d15beedf5ad672a0309a"; # "dev";
      sha256 = "sha256-w0dwRNsbMGkX5FaI+0j6I+qLh7q/rkw8L22lYHqMmGI="; #pkgs.lib.fakeSha256;
    };

    doctest-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "doctest";
      rev    = "5d47e8591862a89dac01be52fe1a89e46285d2df";
      sha256 = "sha256-8eU9l4QNRGlCcMQ/9JN0q83GIch5BX4sFDezhKgpDGM="; #pkgs.lib.fakeSha256;
    };

    ghc-events-analyze-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "ghc-events-analyze";
      rev    = "73fd96f6b833e3f9ae5fc7a2ab85a98e74af8fb9";
      sha256 = "sha256-TW3e2xbUOgvqjk1cr2y2DOc+iuQpVfSJEkP9AgT0xXk="; #pkgs.lib.fakeSha256;
    };

    blaze-svg-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "blaze-svg";
      rev    = "d540dc6c4389636c175a0438ff540255aad3441b";
      sha256 = "sha256-RRa3bB6As5QnHaOH9AP4yc5b4cigGY27MeQsyiYo65k="; #pkgs.lib.fakeSha256;
    };

    # hpkgs = pkgs.haskell.packages.ghc944;
    # Doesn’t work but could be cool: static executables
    # hpkgs = pkgs.pkgsStatic.haskell.packages.ghc961.override {

    # hpkgs = pkgs.haskell.packages.ghc961.override {
    hpkgs = pkgs.haskell.packages.native-bignum.ghc961.override {
      overrides = _: old:
        builtins.mapAttrs makeHaskellPackageSmaller (old // {
          ghc         = smaller-ghc(old.ghc);
        });
    };

    # Doesn’t work but could be cool: static executables
    # hpkgs945 = pkgs.pkgsStatic.haskell.packages.ghc944.override {

    # hpkgs945 = pkgs.haskell.packages.ghc944.override {
    hpkgs945 = pkgs.haskell.packages.native-bignum.ghc944.override {
      overrides = _: old:
        builtins.mapAttrs makeHaskellPackageSmaller (old // {
          ghc = smaller-ghc(old.ghc);
        });
    };

    overrideCabal = revision: editedSha: pkg:
      hlib.overrideCabal pkg {
        inherit revision;
        editedCabalFile = editedSha;
      };

    # hpkgsCabal-raw = pkgs.haskell.packages.ghc944.o

    # Disable profiling and haddock
    makeHaskellPackageSmaller = name: x:
      if builtins.isNull x ||
         builtins.elem
           name
           ["callCabal2nix" "callCabal2nixWithOptions" "haskellSrc2nix" "ghc" "mkDerivation" "buildHaskellPackages" "callHackage" "callHackageDirect" "callPackage" "hackage2nix"]
      then x
      else
        # # If we missed something in the above check, uncomment this and see what’s being accessed
        # builtins.trace { inherit name; type = builtins.typeOf x; }
        hlib.dontHaddock
          (hlib.disableLibraryProfiling
            (hlib.disableExecutableProfiling x));

    hpkgsDoctest = hpkgs.override {
      overrides = _: old:
        builtins.mapAttrs makeHaskellPackageSmaller (old // {
          doctest = (old.callCabal2nix "doctest" doctest-repo {}).overrideAttrs (oldAttrs: oldAttrs // {
            # buildInputs = [haskellPackages.GLFW-b];
            configureFlags = oldAttrs.configureFlags ++ [
              # cabal config passes RTS options to GHC so doctest will receive them too
              # ‘cabal repl --with-ghc=doctest’
              "--ghc-option=-rtsopts"
            ];
          });

          primitive = hlib.dontCheck (old.callHackage "primitive" "0.8.0.0" {});
          tagged = old.callHackage "tagged" "0.8.7" {};
          size-based = hlib.doJailbreak old.size-based;

          syb = old.callHackage "syb" "0.7.2.3" {};
        });
    };

   hpkgsGhcEvensAnalyze = hpkgs945.override {
      overrides = _: old:
        builtins.mapAttrs makeHaskellPackageSmaller (old // {
          ghc-events-analyze = old.callCabal2nix "ghc-events-analyze" ghc-events-analyze-repo {};
          SVGFonts = old.callHackage "SVGFonts" "1.7.0.1" {};
          # blaze-svg = old.callCabal2nix "blaze-svg" blaze-svg-repo {};
          # JuicyPixels = old.callHackage "JuicyPixels" "3.3.8" {};
          # ghc-events = old.callHackage "ghc-events" "0.19.0" {};
          # vector = hlib.dontCheck (old.callHackage "vector" "0.13.0.0" {});
        });
    };

   hpkgsEventlog2html = hpkgs.override {
      overrides = _: old:
        builtins.mapAttrs makeHaskellPackageSmaller (old // {
          eventlog2html = hlib.doJailbreak (hlib.unmarkBroken old.eventlog2html);
          vector-binary-instances = hlib.doJailbreak old.vector-binary-instances;
          statistics = hlib.dontCheck old.statistics;

          # ghc-events-analyze = old.callCabal2nix "ghc-events-analyze" ghc-events-analyze-repo {};
          # SVGFonts = old.callHackage "SVGFonts" "1.7.0.1" {};

          ghc-events = old.callHackage "ghc-events" "0.19.0.1" {};
        });
    };

    # pkgs.haskell.packages.ghc961
    hpkgsCabal = hpkgs945.override {
      overrides = new: old:
        builtins.mapAttrs makeHaskellPackageSmaller (old // {
          ghc = smaller-ghc(old.ghc);

          # builtins.mapAttrs (_name: value: hlib.doJailbreak value) old //
          Cabal = old.callCabal2nix
            "Cabal"
            (cabal-repo + "/Cabal")
            {};
          Cabal-syntax = old.callCabal2nix
            "Cabal-syntax"
            (cabal-repo + "/Cabal-syntax")
            {};
          cabal-install-solver = hlib.doJailbreak (old.callCabal2nix
            "cabal-install-solver"
            (cabal-repo + "/cabal-install-solver")
            {});
          # hlib.dontCheck
          # (old.callHackage "cabal-install-solver" "3.8.1.0" {});
          cabal-install = hlib.doJailbreak (old.callCabal2nix
            "cabal-install"
            (cabal-repo + "/cabal-install")
            { inherit (new) Cabal-described Cabal-QuickCheck Cabal-tree-diff;
            });

          # indexed-traversable = hlib.doJailbreak old.ghc-lib-parser;
          # ghc-lib-parser = hlib.doJailbreak old.ghc-lib-parser;


          # ghc-lib-parser = hlib.markBroken old.ghc-lib-parser;
          # ghc-prof = hlib.doJailbreak old.ghc-prof;

          # process = hlib.dontCheck
          #   (old.callHackage "process" "1.6.15.0" {});

          tar = hlib.doJailbreak old.tar;
          ed25519 = hlib.doJailbreak old.ed25519;
          indexed-traversable = hlib.doJailbreak old.indexed-traversable;

          # ed25519 = #hlib.dontCheck
          #   (overrideCabal
          #     "7"
          #     "sha256-PbBNfBi55oul7vP6fuygXh4kiVjdGCKQyOawEMge9z4="
          #     #"sha256-JKx7Xz2fo8L3AmKzKfKnXyTn/YKfiMGJs4jvobzWfrI="
          #     (old.callHackageDirect {
          #       pkg = "ed25519";
          #       ver = "0.0.5.0";
          #       sha256 = "sha256-x/8O0KFlj2SDVDKp3IPIvqklmZHfBYKGwygbG48q5Ig=";
          #     }
          #       {}));
        });
    };

    # pkgs.haskell.packages.ghc961
    # args.pkgs.haskellPackages
    threadscopePkgs = pkgs.haskell.packages.ghc927.override {
      overrides = new: old:
        builtins.mapAttrs makeHaskellPackageSmaller (old // {
          threadscope = hlib.doJailbreak old.threadscope;
        });
    };

    # nativeDeps = [
    #   pkgs.gmp
    #   pkgs.libffi
    #   pkgs.zlib
    # ];

    disable-docs = ghc:
      ghc.override (oldAttrs: oldAttrs // {
        enableDocs = false;
      });

    smaller-ghc = ghc-pkg:
      ghc-pkg.override (oldAttrs: oldAttrs // {
        enableNativeBignum = true;
        enableDocs         = false;
      });

    relocatable-static-libs-ghc = ghc-pkg:
      ghc-pkg.override (oldAttrs: oldAttrs // {
        enableRelocatedStaticLibs = true;
      });

    wrap-ghc = version: pkg:
      pkgs.runCommand ("wrapped-ghc-" + version) {
        # buildInputs = [ pkgs.makeWrapper ];
      }
        ''
          mkdir -p "$out/bin"
          for x in ghc ghci ghc-pkg haddock-ghc runghc; do
            ln -s "${pkg}/bin/$x-${version}" "$out/bin"
          done
        '';

    wrap-ghc-rename = version: new-suffix: pkg:
      pkgs.runCommand ("wrapped-ghc-" + version) {
        # buildInputs = [ pkgs.makeWrapper ];
      }
        ''
          mkdir -p "$out/bin"
          for x in ghc ghci ghc-pkg haddock-ghc runghc; do
            ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${new-suffix}"
          done
        '';

in {

  ghc        = hpkgs.ghc;

  ghc7103    = wrap-ghc        "7.10.3"            pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc7103.ghc;
  ghc802     = wrap-ghc        "8.0.2"             pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc802.ghc;
  ghc822     = wrap-ghc        "8.2.2"             pinned-pkgs.nixpkgs-19-09.haskell.packages.ghc822.ghc;
  ghc844     = wrap-ghc        "8.4.4"             pinned-pkgs.nixpkgs-20-03.haskell.packages.ghc844.ghc;
  ghc865     = wrap-ghc        "8.6.5"             pinned-pkgs.nixpkgs-20-09.haskell.packages.ghc865.ghc;

  ghc884     = wrap-ghc        "8.8.4"             pkgs.haskell.packages.ghc884.ghc;
  ghc8107    = wrap-ghc        "8.10.7"            (disable-docs pkgs.haskell.packages.ghc8107.ghc);
  #ghc902     = wrap-ghc        "9.0.2"             (smaller-ghc pkgs.haskell.packages.ghc902.ghc);
  ghc927     = wrap-ghc        "9.2.7"             (smaller-ghc pkgs.haskell.packages.ghc927.ghc);
  ghc944     = wrap-ghc        "9.4.4"             (smaller-ghc pkgs.haskell.packages.ghc944.ghc);
  ghc961-pie = wrap-ghc-rename "9.6.1" "9.6.1-pie" (relocatable-static-libs-ghc (smaller-ghc pkgs.haskell.packages.ghc961.ghc));

  # callPackage = newScope {
  #   haskellLib = haskellLibUncomposable.compose;
  #   overrides = pkgs.haskell.packageOverrides;
  # };

  # ghc961  = wrap-ghc "9.6.0.20230111" (import ./ghc-9.6.1-alpha1.nix {
  #   inherit (pkgs)
  #     lib
  #     stdenv
  #     fetchurl
  #     perl
  #     gcc
  #     ncurses5
  #     ncurses6
  #     gmp
  #     libiconv
  #     numactl
  #     libffi
  #     llvmPackages
  #     coreutils
  #     targetPackages;
  #
  #   # llvmPackages = pkgs.llvmPackages_13;
  # });

  cabal-install      = hpkgsCabal.cabal-install;
  doctest            = hpkgsDoctest.doctest;
  eventlog2html      = hpkgsEventlog2html.eventlog2html;
  fast-tags          = hpkgs945.fast-tags;
  ghc-events-analyze = hpkgsGhcEvensAnalyze.ghc-events-analyze;
  hp2pretty          = hpkgs945.hp2pretty;
  pretty-show        = hpkgs.pretty-show;
  profiterole        = hpkgs945.profiterole;
  # threadscope        = threadscopePkgs.threadscope;
  universal-ctags    = pkgs.universal-ctags;

  clang = pkgs.clang_13;
  llvm  = pkgs.llvm_13;
  lld   = pkgs.lld_13;

  cmake      = pkgs.cmake;
  gnumake    = pkgs.gnumake;
  gdb        = pkgs.gdb;
  patchelf   = pkgs.patchelf;
  pkg-config = pkgs.pkg-config;

  diffutils = pkgs.diffutils;
}

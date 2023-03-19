args @
  { pinned-pkgs
  , nixpkgs-unstable
  , system
  # , pkgs
  , ...
  }:
let pkgs = nixpkgs-unstable.legacyPackages.${system};
    t    = pkgs.lib.trivial;
    hl   = pkgs.haskell.lib;

    # hpkgs = pkgs.haskell.packages.ghc924;

    cabal-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "cabal";
      rev    = "121f55e792222d71ad78d15beedf5ad672a0309a"; # "dev";
      sha256 = "sha256-w0dwRNsbMGkX5FaI+0j6I+qLh7q/rkw8L22lYHqMmGI="; #pkgs.lib.fakeSha256;
    };

    # hpkgs = pkgs.haskell.packages.ghc944;
    hpkgs = pkgs.haskell.packages.ghc961.override {
      overrides = new: old: {
        ghc = smaller-ghc(old.ghc);
      };
    };

    overrideCabal = revision: editedSha: pkg:
      pkgs.haskell.lib.overrideCabal pkg {
        inherit revision;
        editedCabalFile = editedSha;
      };

    # hpkgsCabal-raw = pkgs.haskell.packages.ghc944.o

    hpkgs944 = pkgs.haskell.packages.ghc944.override {
      overrides = new: old: {
        ghc = smaller-ghc(old.ghc);
      };
    };

    # pkgs.haskell.packages.ghc961
    hpkgsCabal = hpkgs944.override {
      overrides = new: old: {
        ghc = smaller-ghc(old.ghc);

        # builtins.mapAttrs (_name: value: pkgs.haskell.lib.doJailbreak value) old //
        Cabal = new.callCabal2nix
          "Cabal"
          (cabal-repo + "/Cabal")
          {};
        Cabal-syntax = new.callCabal2nix
          "Cabal-syntax"
          (cabal-repo + "/Cabal-syntax")
          {};
        cabal-install-solver = pkgs.haskell.lib.doJailbreak (new.callCabal2nix
          "cabal-install-solver"
          (cabal-repo + "/cabal-install-solver")
          {});
        # pkgs.haskell.lib.dontCheck
        # (new.callHackage "cabal-install-solver" "3.8.1.0" {});
        cabal-install = pkgs.haskell.lib.doJailbreak (new.callCabal2nix
          "cabal-install"
          (cabal-repo + "/cabal-install")
          { inherit (new) Cabal-described Cabal-QuickCheck Cabal-tree-diff;
          });

        # indexed-traversable = pkgs.haskell.lib.doJailbreak old.ghc-lib-parser;
        # ghc-lib-parser = pkgs.haskell.lib.doJailbreak old.ghc-lib-parser;


        # ghc-lib-parser = pkgs.haskell.lib.markBroken old.ghc-lib-parser;
        # ghc-prof = pkgs.haskell.lib.doJailbreak old.ghc-prof;

        # process = pkgs.haskell.lib.dontCheck
        #   (new.callHackage "process" "1.6.15.0" {});

        tar = pkgs.haskell.lib.doJailbreak old.tar;
        ed25519 = pkgs.haskell.lib.doJailbreak old.ed25519;
        indexed-traversable = pkgs.haskell.lib.doJailbreak old.indexed-traversable;

        # ed25519 = #pkgs.haskell.lib.dontCheck
        #   (overrideCabal
        #     "7"
        #     "sha256-PbBNfBi55oul7vP6fuygXh4kiVjdGCKQyOawEMge9z4="
        #     #"sha256-JKx7Xz2fo8L3AmKzKfKnXyTn/YKfiMGJs4jvobzWfrI="
        #     (new.callHackageDirect {
        #       pkg = "ed25519";
        #       ver = "0.0.5.0";
        #       sha256 = "sha256-x/8O0KFlj2SDVDKp3IPIvqklmZHfBYKGwygbG48q5Ig=";
        #     }
        #       {}));
      };
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

in {

  ghc = hpkgs.ghc;

  ghc7103 = wrap-ghc "7.10.3" pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc7103.ghc;
  ghc802  = wrap-ghc "8.0.2"  pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc802.ghc;
  ghc822  = wrap-ghc "8.2.2"  pinned-pkgs.nixpkgs-19-09.haskell.packages.ghc822.ghc;
  ghc844  = wrap-ghc "8.4.4"  pinned-pkgs.nixpkgs-20-03.haskell.packages.ghc844.ghc;
  ghc865  = wrap-ghc "8.6.5"  pinned-pkgs.nixpkgs-20-09.haskell.packages.ghc865.ghc;

  ghc884  = wrap-ghc "8.8.4"  pkgs.haskell.packages.ghc884.ghc;
  ghc8107 = wrap-ghc "8.10.7" (disable-docs pkgs.haskell.packages.ghc8107.ghc);
  ghc902  = wrap-ghc "9.0.2"  (smaller-ghc pkgs.haskell.packages.ghc902.ghc);
  ghc927  = wrap-ghc "9.2.7"  (smaller-ghc pkgs.haskell.packages.ghc927.ghc);
  ghc944  = wrap-ghc "9.4.4"  (smaller-ghc pkgs.haskell.packages.ghc944.ghc);

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

  cabal-install = hpkgsCabal.cabal-install;

  fast-tags          = hpkgs944.fast-tags;
  hp2pretty          = hpkgs944.hp2pretty;
  pretty-show        = hpkgs.pretty-show;
  profiterole        = hpkgs944.profiterole;
  threadscope        = args.pkgs.haskellPackages.threadscope;
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

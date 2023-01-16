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
      rev    = "c2473316fed37102e45b3a277bab4018441edd9e"; # "dev";
      sha256 = "sha256-/ii9zRQ6+Nd63Z75p6pDP6IZggY8kz8HddeD3gPupOM="; # pkgs.lib.fakeSha256;
    };

    hpkgs = pkgs.haskell.packages.ghc944;

    hpkgsCabal = hpkgs.override {
      overrides = new: old:
        # builtins.mapAttrs (_name: value: pkgs.haskell.lib.doJailbreak value) old //
        {
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

          ghc-prof = pkgs.haskell.lib.doJailbreak old.ghc-prof;

          # process = pkgs.haskell.lib.dontCheck
          #   (new.callHackage "process" "1.6.15.0" {});

          # dec = pkgs.haskell.lib.dontCheck
          #   (new.callHackageDirect {
          #     pkg = "dec";
          #     ver = "0.0.5";
          #     sha256 = "sha256-ouVCccKpYMubd/Btbz+SkPqXE+CmM+deuuaRy1YfiCk=";
          #   }
          #   {});
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

  ghc = hpkgs.ghc.override (oldAttrs: oldAttrs // {
    enableNativeBignum = true;
    enableDocs         = false;
  });

  ghc7103 = wrap-ghc "7.10.3" pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc7103.ghc;
  ghc802  = wrap-ghc "8.0.2"  pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc802.ghc;
  ghc822  = wrap-ghc "8.2.2"  pinned-pkgs.nixpkgs-19-09.haskell.packages.ghc822.ghc;
  ghc844  = wrap-ghc "8.4.4"  pinned-pkgs.nixpkgs-20-03.haskell.packages.ghc844.ghc;
  ghc865  = wrap-ghc "8.6.5"  pinned-pkgs.nixpkgs-20-09.haskell.packages.ghc865.ghc;

  ghc884  = wrap-ghc "8.8.4"  pkgs.haskell.packages.ghc884.ghc;
  ghc8107 = wrap-ghc "8.10.7" (disable-docs pkgs.haskell.packages.ghc8107.ghc);
  ghc902  = wrap-ghc "9.0.2"  (disable-docs pkgs.haskell.packages.ghc902.ghc);
  ghc925  = wrap-ghc "9.2.5"  (disable-docs pkgs.haskell.packages.ghc925.ghc);

  cabal-install = hpkgsCabal.cabal-install;

  profiterole        = hpkgsCabal.profiterole;
  hp2pretty          = hpkgs.hp2pretty;
  fast-tags          = hpkgs.fast-tags;
  threadscope        = args.pkgs.haskellPackages.threadscope;
  universal-ctags    = pkgs.universal-ctags;
  pretty-show        = hpkgs.pretty-show;

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

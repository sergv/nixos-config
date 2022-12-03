{ pkgs, ... }:
let # pkgs = nixpkgs.legacyPackages.${system};
    t    = pkgs.lib.trivial;
    hl   = pkgs.haskell.lib;

    # hpkgs = pkgs.haskell.packages.ghc924;

    cabal-repo = pkgs.fetchFromGitHub {
      owner = "sergv";
      repo = "cabal";
      rev = "dev";
      sha256 = "sha256-m0hHnC460ZoB9o/YweRMCG5onqgMrwPfexYzZDriR30="; # pkgs.lib.fakeSha256;
    };

    hpkgs = pkgs.haskell.packages.ghc943;

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

in {

  ghc = hpkgs.ghc.override (oldAttrs: {
    enableNativeBignum = true;
    enableDocs         = false;
  });

  cabal-install = hpkgsCabal.cabal-install;

  profiterole     = hpkgsCabal.profiterole;
  hp2pretty       = hpkgs.hp2pretty;
  fast-tags       = hpkgs.fast-tags;
  universal-ctags = pkgs.universal-ctags;

  clang = pkgs.clang_13;
  llvm = pkgs.llvm_13;
  lld = pkgs.lld_13;

  gdb = pkgs.gdb;

  pkg-config = pkgs.pkg-config;

  cmake = pkgs.cmake;
  git = pkgs.git;
  diffutils = pkgs.diffutils;

}

{ pkgs
, ...
}:
let hlib = pkgs.haskell.lib;

    # Disable profiling and haddock
    makeHaskellPackageSmaller = x:
      hlib.dontHaddock
        (hlib.disableLibraryProfiling
          (hlib.disableExecutableProfiling x));

    makeHaskellPackageAttribSmaller = name: x:
      if builtins.isNull x ||
         builtins.elem
           name
           # May need to add more attributes here...
           ["callCabal2nix" "callCabal2nixWithOptions" "haskellSrc2nix" "ghc" "mkDerivation" "buildHaskellPackages" "callHackage" "callHackageDirect" "callPackage" "hackage2nix" "generateOptparseApplicativeCompletion" "generateOptparseApplicativeCompletions"]
           # "jailbreak-cabal"
      then x
      else
        # # If we missed something in the above check, uncomment this and see what’s being accessed
        # builtins.trace { inherit name; type = builtins.typeOf x; }
        (makeHaskellPackageSmaller x);

    smaller-ghc = ghc-pkg:
      ghc-pkg.override (oldAttrs: oldAttrs // {
        enableNativeBignum = true;
        enableDocs         = false;
      });

    enable-ghc-docs = ghc-pkg:
      ghc-pkg.override (oldAttrs: oldAttrs // {
        enableDocs         = true;
      });

in {
  inherit makeHaskellPackageSmaller makeHaskellPackageAttribSmaller smaller-ghc;

  smaller-hpkgs-no-ghc = hpkgs:
    hpkgs.extend (_: old:
      builtins.mapAttrs makeHaskellPackageAttribSmaller old
    );

  smaller-hpkgs = hpkgs:
    hpkgs.extend (_: old:
      builtins.mapAttrs makeHaskellPackageAttribSmaller (old // {
        ghc = smaller-ghc(old.ghc);
      }));
}

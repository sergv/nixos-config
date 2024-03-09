{ pkgs
}:
let hlib = pkgs.haskell.lib;

    # Disable profiling and haddock
    makeHaskellPackageSmaller = x: x;
      #hlib.dontHaddock
      #  (hlib.disableLibraryProfiling
      #    (hlib.disableExecutableProfiling x));

    makeHaskellPackageAttribSmaller = name: x: x;
      #if builtins.isNull x ||
      #   builtins.elem
      #     name
      #     # May need to add more attributes here...
      #      ["callCabal2nix" "callCabal2nixWithOptions" "haskellSrc2nix" "ghc" "mkDerivation" "buildHaskellPackages" "callHackage" "callHackageDirect" "callPackage" "hackage2nix" "generateOptparseApplicativeCompletion" "generateOptparseApplicativeCompletions" "native-bignum"]
      #     # "jailbreak-cabal"
      #then x
      #else
      #  # # If we missed something in the above check, uncomment this and see what’s being accessed
      #  # builtins.trace { inherit name; type = builtins.typeOf x; }
      #  (makeHaskellPackageSmaller x);

    smaller-ghc = ghc-pkg: ghc-pkg;
      #ghc-pkg.override (oldAttrs: oldAttrs // {
      #  enableNativeBignum = true;
      #  enableDocs         = false;
      #});

    enable-ghc-docs = ghc-pkg: ghc-pkg;
      # ghc-pkg.override (oldAttrs: oldAttrs // {
      #   enableDocs         = true;
      # });



    # Regular extend doesn’t work with haskell packages - it nukes .override
    # thus preventing further calls to .override.
    #
    # f should be of the form
    # (self: super: { ...  })
    fixedExtend = target: f: target;
     # target.override (old: {
     #   overrides = pkgs.lib.composeExtensions (old.overrides or (_: _: {})) f;
     #});

in {
  inherit makeHaskellPackageSmaller makeHaskellPackageAttribSmaller smaller-ghc fixedExtend;

  smaller-hpkgs-no-ghc = hpkgs: hpkgs;
    # fixedExtend hpkgs (_: old:
    #   builtins.mapAttrs makeHaskellPackageAttribSmaller old
    # );

  smaller-hpkgs = hpkgs: hpkgs;
    # # builtins.trace (builtins.attrNames hpkgs)
    #   (fixedExtend hpkgs (_: old:
    #     builtins.mapAttrs makeHaskellPackageAttribSmaller (old // {
    #       ghc = smaller-ghc old.ghc;
    #     })));
}

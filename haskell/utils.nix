{ pkgs
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
           ["callCabal2nix" "callCabal2nixWithOptions" "haskellSrc2nix" "ghc" "mkDerivation" "buildHaskellPackages" "callHackage" "callHackageDirect" "callPackage" "hackage2nix" "generateOptparseApplicativeCompletion" "generateOptparseApplicativeCompletions" "native-bignum"]
          # "jailbreak-cabal"
      then x
      else
       # # If we missed something in the above check, uncomment this and see what’s being accessed
       # builtins.trace { inherit name; type = builtins.typeOf x; }
       (makeHaskellPackageSmaller x);

    ghc-version-ge = ghc-pkg: target-version:
      let versionGE = to-check: target-version:
            builtins.compareVersions to-check target-version >= 0;
      in (ghc-pkg ? version) && versionGE ghc-pkg.version target-version;

    # smaller-ghc = ghc-pkg:
    #   if ghc-version-ge ghc-pkg "9.6"
    #   then
    #     let args = pkgs.lib.functionArgs ghc-pkg.override;
    #         is-non-bin-distribution = args ? enableNativeBignum || args ? enableDocs;
    #     in
    #       if is-non-bin-distribution
    #       then ghc-pkg.override (_: {
    #         enableNativeBignum = true;
    #         enableDocs         = false;
    #       })
    #       else ghc-pkg
    #   else
    #     # Don’t bother with older ghcs.
    #     ghc-pkg;

    enable-unit-ids-for-newer-ghc = ghc-pkg:
      if ghc-version-ge ghc-pkg "9.8"
      then
        ghc-pkg.overrideAttrs (old: {
          hadrianFlags = (old.hadrianFlags or []) ++ ["--hash-unit-ids"];
          hadrianArgs  = (old.hadrianArgs or [])  ++ ["--hash-unit-ids"];
        })
      else
        ghc-pkg;

    # Regular extend doesn’t work with haskell packages - it nukes .override
    # thus preventing further calls to .override.
    #
    # f should be of the form
    # (self: super: { ...  })
    fixedExtend = target: f:
      target.override (old: {
        overrides = pkgs.lib.composeExtensions (old.overrides or (_: _: {})) f;
      });

in {
  inherit makeHaskellPackageSmaller makeHaskellPackageAttribSmaller fixedExtend ghc-version-ge;

  inherit enable-unit-ids-for-newer-ghc;

  smaller-hpkgs-no-ghc = hpkgs:
    fixedExtend hpkgs (_: old:
      builtins.mapAttrs makeHaskellPackageAttribSmaller old
    );

  # inherit smaller-ghc;
  #
  # smaller-hpkgs = hpkgs:
  #   # builtins.trace (builtins.attrNames hpkgs)
  #     (fixedExtend hpkgs (_: old:
  #       builtins.mapAttrs makeHaskellPackageAttribSmaller (old // {
  #         ghc = smaller-ghc old.ghc;
  #       })));
}

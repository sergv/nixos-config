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

    hutils = import haskell/utils.nix { inherit pkgs; };

    # hpkgs = pkgs.haskell.packages.ghc924;

    cabal-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "cabal";
      rev    = "72937b1cfca807e0047f92e11fb2ab2061aed2fb"; # "dev";
      sha256 = "sha256-EpA1Rt8++OLhi3zKc+xlsf+NhH9fML4A2pUDPs8MNiM="; #pkgs.lib.fakeSha256;
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

    # hpkgs = pkgs.haskell.packages.ghc945;
    # Doesn’t work but could be cool: static executables
    # hpkgs = pkgs.pkgsStatic.haskell.packages.ghc961.override {

    # hpkgs = pkgs.haskell.packages.ghc961.override {

    # Doesn’t work but could be cool: static executables
    # hpkgs948 = pkgs.pkgsStatic.haskell.packages.ghc945.override {

    hpkgs948 = hutils.smaller-hpkgs pkgs.haskell.packages.native-bignum.ghc948;
    hpkgs964 = hutils.smaller-hpkgs pkgs.haskell.packages.native-bignum.ghc964;
    hpkgs981 = hutils.smaller-hpkgs pkgs.haskell.packages.native-bignum.ghc981;

    overrideCabal = revision: editedSha: pkg:
      hlib.overrideCabal pkg {
        inherit revision;
        editedCabalFile = editedSha;
      };

    # hpkgsCabal-raw = pkgs.haskell.packages.ghc945.o

    hpkgsDoctest = hpkgs964.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        doctest = (old.callCabal2nix "doctest" doctest-repo {}).overrideAttrs (oldAttrs: oldAttrs // {
          # buildInputs = [haskellPackages.GLFW-b];
          configureFlags = oldAttrs.configureFlags ++ [
            # cabal config passes RTS options to GHC so doctest will receive them too
            # ‘cabal repl --with-ghc=doctest’
            "--ghc-option=-rtsopts"
          ];
        });

        # primitive = hlib.dontCheck (old.callHackage "primitive" "0.8.0.0" {});
        # tagged = old.callHackage "tagged" "0.8.7" {};
        # size-based = hlib.doJailbreak old.size-based;
        #
        # syb = old.callHackage "syb" "0.7.2.3" {};
      }));

    hpkgsGhcEvensAnalyze = hpkgs948.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        ghc-events-analyze = old.callCabal2nix "ghc-events-analyze" ghc-events-analyze-repo {};
        SVGFonts           = old.callHackage "SVGFonts" "1.7.0.1" {};
        ghc-events         = old.callHackage "ghc-events" "0.19.0.1" {};

        # Disable tests which take around 1 hour!
        statistics = hlib.dontCheck old.statistics;
      }));

    hpkgsEventlog2html = hpkgs964.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        eventlog2html = hlib.doJailbreak (hlib.unmarkBroken old.eventlog2html);
        vector-binary-instances = hlib.doJailbreak old.vector-binary-instances;

        ghc-events = old.callHackage "ghc-events" "0.19.0.1" {};
        # Disable tests which take around 1 hour!
        statistics = hlib.dontCheck old.statistics;
      }));

    hpkgsProfiterole = hpkgs964.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        profiterole = old.profiterole;
        ghc-prof    = hlib.doJailbreak old.ghc-prof;
      }));

    # pkgs.haskell.packages.ghc961
    hpkgsCabal = hpkgs964.extend (new: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        ghc = hutils.smaller-ghc(old.ghc);

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

        semaphore-compat = hlib.markUnbroken old.semaphore-compat;

        # Disable tests which take around 1 hour!
        statistics = hlib.dontCheck old.statistics;

        # ghc-lib-parser = hlib.markBroken old.ghc-lib-parser;
        # ghc-prof = hlib.doJailbreak old.ghc-prof;

        # process = hlib.dontCheck
        #   (old.callHackage "process" "1.6.15.0" {});

        # tar = hlib.doJailbreak old.tar;
        # ed25519 = hlib.doJailbreak old.ed25519;
        # indexed-traversable = hlib.doJailbreak old.indexed-traversable;


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
      }));

    # pkgs.haskell.packages.ghc961
    # args.pkgs.haskellPackages
    threadscopePkgs = pkgs.haskell.packages.ghc928.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        threadscope = hlib.doJailbreak old.threadscope;
      }));

    # nativeDeps = [
    #   pkgs.gmp
    #   pkgs.libffi
    #   pkgs.zlib
    # ];

    disable-docs = ghc:
      ghc.override (oldAttrs: oldAttrs // {
        enableDocs = false;
      });

    relocatable-static-libs-ghc = ghc-pkg:
      ghc-pkg.override (oldAttrs: oldAttrs // {
        enableRelocatedStaticLibs = true;
      });

    # So that I won’t need to litter everywhere with those pesky trivial flake.nix & flak.lock files
    # that only enable zlib. Locks also require regular maintenance, which is unbearable.
    bakedInNativeDeps = [ pkgs.zlib ];

    wrap-cabal = pkg:
      pkgs.runCommand ("wrapped-cabal") {
        # Will require at runtime both libraries and headers (development files) so we’re
        # taking both.
        buildInputs       = pkgs.lib.lists.concatMap (x: if builtins.hasAttr "dev" x then [x x.dev] else [x]) bakedInNativeDeps;
        nativeBuildInputs = [ pkgs.makeWrapper ];
      }
        ''
            mkdir -p "$out/bin"
            makeWrapper "${pkg}/bin/cabal" "$out/bin/cabal" --suffix "PKG_CONFIG_PATH" ":" "${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" bakedInNativeDeps}"
          '';

    wrap-ghc = version: alias-versions: pkg:
      let f = alias-version:
            assert (builtins.isString alias-version || builtins.isNull alias-version);
            let suffix = if builtins.isNull alias-version then "" else "-${alias-version}";
            in ''ln -s "$out/bin/$x-${version}" "$out/bin/$x${suffix}"'';
      in
        pkgs.runCommand ("wrapped-ghc-" + version) {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        }
          # ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}"
          ''
            mkdir -p "$out/bin"
            for x in ghc ghci ghc-pkg haddock-ghc runghc; do
              # makeWrapper "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}" --suffix "LD_LIBRARY_PATH" ":" "${pkgs.lib.makeLibraryPath bakedInNativeDeps}"
              ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}"
              ${if builtins.isList alias-versions
                then builtins.concatStringsSep "\n" (builtins.map f alias-versions)
                else f alias-versions}
            done
          '';

    wrap-ghc-filter-selected-args = filtered-args: version: alias-version: pkg:
      let wrapped-ghc = pkgs.writeShellScript ("filtering-ghc-" + version)
        ''
          args=("''${@}")

          len="''${#args[@]}"

          for (( i = 0; i < "$len"; ++i )); do
            case "''${args[i]}" in
              ${builtins.concatStringsSep " | " filtered-args} )
                unset args[i];
              ;;
            esac
          done

          exec "${pkg}/bin/ghc-${version}" "''${args[@]}"
        '';
      in
        pkgs.runCommand ("wrapped-filtering-ghc-" + version) {
          buildInptus = [ wrapped-ghc ];
        }
          ''
            mkdir -p "$out/bin"
            ln -s "${wrapped-ghc}" "$out/bin/ghc-${version}"
            ln -s "$out/bin/ghc-${version}" "$out/bin/ghc-${alias-version}"
            for x in ghci ghc-pkg haddock-ghc runghc; do
              ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}"
              ln -s "$out/bin/$x-${version}"   "$out/bin/$x-${alias-version}"
            done
          '';

    wrap-ghc-filter-hide-source-paths = wrap-ghc-filter-selected-args [
      "-fhide-source-paths"
    ];

    wrap-ghc-filter-all = wrap-ghc-filter-selected-args [
      "-fhide-source-paths"
      "-fprint-potential-instances"
      "-fprint-expanded-synonyms"
    ];

    wrap-ghc-rename = version: new-suffix: pkg:
      pkgs.runCommand ("wrapped-renamed-ghc-" + version) {
        # buildInputs = [ pkgs.makeWrapper ];
      }
        ''
          mkdir -p "$out/bin"
          for x in ghc ghci ghc-pkg haddock-ghc runghc; do
            ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${new-suffix}"
          done
        '';

    disableAllHardening = x: x.overrideAttrs (old: {
      hardeningDisable = ["all"];
    });

    ghc982 =
      let old-ghc = pkgs.haskell.compiler.ghc981;
          version = "9.8.2";
          rev     = "f3225ed4b3f3c4309f9342c5e40643eeb0cc45da";
          ghcSrc = pkgs.fetchgit {
            url    = "https://gitlab.haskell.org/ghc/ghc.git";
            sha256 = "sha256-EhZSGnr12aWkye9v5Jsm91vbMi/EDzRAPs8/W2aKTZ8="; #pkgs.lib.fakeSha256;
            inherit rev;
          };
      in
        disableAllHardening (hutils.smaller-ghc ((old-ghc.override (old: old // {
          hadrian = old-ghc.hadrian.override (old2: old2 // {
            inherit ghcSrc;
            ghcVersion = version;
          });
          inherit ghcSrc;
        }
        )).overrideAttrs (old: {
          inherit version;
          preConfigure = builtins.replaceStrings [ old-ghc.version ] [ "${version}" ] old.preConfigure +
            # Do this if taking sources from git directly.
            ''
              echo ${version} > VERSION
              echo ${rev} > GIT_COMMIT_ID
              ./boot
            '';
        })));

in {

  ghc7103    = wrap-ghc-filter-all               "7.10.3" "7.10"       pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc7103.ghc;
  ghc802     = wrap-ghc-filter-hide-source-paths "8.0.2"  "8.0"        pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc802.ghc;

  ghc822     = wrap-ghc                          "8.2.2"  "8.2"        pinned-pkgs.nixpkgs-19-09.haskell.packages.ghc822.ghc;
  ghc844     = wrap-ghc                          "8.4.4"  "8.4"        pinned-pkgs.nixpkgs-20-03.haskell.packages.ghc844.ghc;

  ghc865     = wrap-ghc                          "8.6.5"  "8.6"        pinned-pkgs.nixpkgs-20-09.haskell.packages.ghc865.ghc;

  ghc884     = wrap-ghc                          "8.8.4"  "8.8"        pinned-pkgs.nixpkgs-23-11.haskell.packages.ghc884.ghc;

  ghc8107    = wrap-ghc                          "8.10.7" "8.10"       (disable-docs pkgs.haskell.packages.ghc8107.ghc);
  ghc902     = wrap-ghc                          "9.0.2"  "9.0"        (hutils.smaller-ghc pkgs.haskell.packages.ghc902.ghc);
  ghc928     = wrap-ghc                          "9.2.8"  "9.2"        (hutils.smaller-ghc pkgs.haskell.packages.ghc928.ghc);
  ghc948     = wrap-ghc                          "9.4.8"  "9.4"        (hutils.smaller-ghc pkgs.haskell.packages.ghc948.ghc);

  ghc964     = wrap-ghc                          "9.6.4"  "9.6"        (hutils.smaller-ghc pkgs.haskell.packages.ghc964.ghc);
  ghc982     = wrap-ghc                          "9.8.2"  ["9.8" null] ghc982;

  #ghc961-pie = wrap-ghc-rename "9.6.1" "9.6.1-pie" (relocatable-static-libs-ghc (hutils.smaller-ghc pkgs.haskell.packages.ghc961.ghc));

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

  alex               = hlib.justStaticExecutables hpkgs964.alex;
  happy              = hlib.justStaticExecutables hpkgs964.happy;
  cabal-install      = wrap-cabal (hlib.justStaticExecutables hpkgsCabal.cabal-install);
  doctest            = hlib.justStaticExecutables hpkgsDoctest.doctest;
  eventlog2html      = hlib.justStaticExecutables hpkgsEventlog2html.eventlog2html;
  fast-tags          = hlib.justStaticExecutables hpkgs964.fast-tags;
  ghc-events-analyze = hlib.justStaticExecutables hpkgsGhcEvensAnalyze.ghc-events-analyze;
  hp2pretty          = hlib.justStaticExecutables hpkgs964.hp2pretty;
  pretty-show        = hlib.justStaticExecutables hpkgs981.pretty-show;
  profiterole        = hlib.justStaticExecutables hpkgsProfiterole.profiterole;
  # threadscope        = threadscopePkgs.threadscope;
  universal-ctags    = pkgs.universal-ctags;

  gcc   = pkgs.gcc;
  # clang = pkgs.clang_13;
  llvm  = pkgs.llvm_13;
  lld   = pkgs.lld_13;

  cmake      = pkgs.cmake;
  gnumake    = pkgs.gnumake;
  gdb        = pkgs.gdb;
  patchelf   = pkgs.patchelf;
  pkg-config = pkgs.pkg-config;

  diffutils = pkgs.diffutils;
}

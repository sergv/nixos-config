args @
  { pinned-pkgs
  # , nixpkgs-stable
  , nixpkgs-unstable
  , system
  , pkgs
  , pkgs-cross-win
  , ...
  }:
let #pkgs-pristine = nixpkgs-unstable.legacyPackages."${system}";
    t             = pkgs.lib.trivial;
    hlib          = pkgs.haskell.lib;

    hutils = import haskell/utils.nix { inherit pkgs; };

    # hpkgs = pkgs.haskell.packages.ghc924;

    cabal-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "cabal";
      rev    = "33156b80a813c9b6f4ad65a87ecc6e9fe6d7e86a"; # "dev";
      sha256 = "sha256-oQ8utMGZbRwtztGdN86IKneKD7lEZZLL8N8f6TpceFU="; #pkgs.lib.fakeSha256;
    };

    doctest-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "doctest";
      rev    = "b996c217e72b9b53f8315933d12e41eef5692455";
      sha256 = "sha256-UIPzjWJeKYGEKlcrSEv8ey7Ln40lxIxTneQPjAqFraY="; #pkgs.lib.fakeSha256;
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

    fast-tags-repo = pkgs.fetchFromGitHub {
      owner  = "sergv";
      repo   = "fast-tags";
      rev    = "3e44dbcc3da564ed7dd057ba2563752065985486";
      sha256 = "sha256-b/2j3qob6+cqhWT312N2rWCmq2VB2x/chfkOYV8qZbM="; #pkgs.lib.fakeSha256;
    };

    # hpkgs = pkgs.haskell.packages.ghc945;
    # Doesn’t work but could be cool: static executables
    # hpkgs = pkgs.pkgsStatic.haskell.packages.ghc961.override {

    # hpkgs = pkgs.haskell.packages.ghc961.override {

    # Doesn’t work but could be cool: static executables
    # hpkgs948 = pkgs.pkgsStatic.haskell.packages.ghc945.override {

    # hpkgs948 = hutils.smaller-hpkgs pkgs.haskell.packages.native-bignum.ghc948;
    hpkgs96 = hutils.smaller-hpkgs pkgs.haskell.packages.native-bignum.ghc966;
    hpkgs910 = hutils.smaller-hpkgs-no-ghc pkgs.haskell.packages.native-bignum.ghc9101;
    # hpkgs981 = hutils.smaller-hpkgs pkgs.haskell.packages.native-bignum.ghc981;

    overrideCabal = revision: editedSha: pkg:
      hlib.overrideCabal pkg {
        inherit revision;
        editedCabalFile = editedSha;
      };

    # hpkgsCabal-raw = pkgs.haskell.packages.ghc945.o

    hashable-pkg = pkgs:
      hlib.dontCheck
        (pkgs.callHackageDirect
          {
            pkg    = "hashable";
            ver    = "1.5.0.0";
            sha256 = "sha256-IYAGl8K4Fo1DGSE2kok3HMtwUOJ/mwGHzVJfNYQTAsI="; #pkgs.lib.fakeSha256;
          }
          {});

    allowGhcReference = x: hlib.overrideCabal x (drv: { disallowGhcReference = false; });

    hpkgsDoctest = hpkgs910.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        doctest =
          hlib.dontCheck ((old.callCabal2nix "doctest" doctest-repo {}).overrideAttrs (oldAttrs: oldAttrs // {
            # buildInputs = [haskellPackages.GLFW-b];
            configureFlags = oldAttrs.configureFlags ++ [
              # cabal config passes RTS options to GHC so doctest will receive them too
              # ‘cabal repl --with-ghc=doctest’
              "--ghc-option=-rtsopts"
            ];
          }));

        # primitive = hlib.dontCheck (old.callHackage "primitive" "0.8.0.0" {});
        # tagged = old.callHackage "tagged" "0.8.7" {};
        # size-based = hlib.doJailbreak old.size-based;
        #
        # syb = old.callHackage "syb" "0.7.2.3" {};
      }));

    hpkgsGhcEvensAnalyze = hpkgs96.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        ghc-events-analyze = hlib.doJailbreak (old.callCabal2nix "ghc-events-analyze" ghc-events-analyze-repo {});
        SVGFonts           = old.callHackage "SVGFonts" "1.7.0.1" {};
        ghc-events         = old.callHackage "ghc-events" "0.19.0.1" {};

        # Disable tests which take around 1 hour!
        statistics = hlib.dontCheck old.statistics;
      }));

    hpkgsEventlog2html = hpkgs96.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        eventlog2html = hlib.doJailbreak (hlib.unmarkBroken old.eventlog2html);
        vector-binary-instances = hlib.doJailbreak old.vector-binary-instances;

        ghc-events = old.callHackage "ghc-events" "0.19.0.1" {};
        # Disable tests which take around 1 hour!
        statistics = hlib.dontCheck old.statistics;
      }));

    hpkgsProfiterole = hpkgs96.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        profiterole = old.profiterole;
        ghc-prof    = hlib.doJailbreak old.ghc-prof;
      }));

    # pkgs.haskell.packages.ghc961
    hpkgsCabal = hpkgs910.extend (new: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller
        (old // {
        ghc = hutils.smaller-ghc(old.ghc);

        # builtins.mapAttrs (_name: value: hlib.doJailbreak value) old //
        Cabal = old.callCabal2nix
          "Cabal"
          (cabal-repo + "/Cabal")
          {};
        # Cabal-described = old.callCabal2nix
        #   "Cabal-described"
        #   (cabal-repo + "/Cabal-described")
        #   {};
        # Cabal-hooks = old.callCabal2nix
        #   "Cabal-hooks"
        #   (cabal-repo + "/Cabal-hooks")
        #   {};
        Cabal-syntax = old.callCabal2nix
          "Cabal-syntax"
          (cabal-repo + "/Cabal-syntax")
          {};
        Cabal-tests = old.callCabal2nix
          "Cabal-tests"
          (cabal-repo + "/Cabal-tests")
          {};
        cabal-install-solver = hlib.doJailbreak (old.callCabal2nix
          "cabal-install-solver"
          (cabal-repo + "/cabal-install-solver")
          {});
        # hlib.dontCheck
        # (old.callHackage "cabal-install-solver" "3.8.1.0" {});
        cabal-install = # hlib.doJailbreak
          (old.callCabal2nix
          "cabal-install"
          (cabal-repo + "/cabal-install")
          { inherit (new) Cabal-described Cabal-QuickCheck Cabal-tree-diff Cabal-tests;
          });

        hackage-security = hlib.doJailbreak
          (old.callHackage "hackage-security" "0.6.2.6" {});

        # semaphore-compat = hlib.markUnbroken old.semaphore-compat;

        # Force reinstall
        semaphore-compat = old.callHackage "semaphore-compat" "1.0.0" {};

        # Disable tests which take around 1 hour!
        statistics = hlib.dontCheck old.statistics;

        async = hlib.dontCheck old.async;
        vector = hlib.dontCheck old.vector;

        file-io = hlib.dontCheck old.file-io;

        uuid-types = hlib.doJailbreak old.uuid-types;
        strict = hlib.doJailbreak old.strict;

        hashable = hashable-pkg old;

        unix = hlib.dontCheck
          (old.callHackageDirect
            {
              pkg    = "unix";
              ver    = "2.8.6.0";
              sha256 = "sha256-Tnkda3SJu5R2O9bYbrw+Fy/OQNxqOfWBP+Zv0jqDI6Q="; #pkgs.lib.fakeSha256;
            }
            {});

        tasty = hlib.dontCheck
          (old.callHackageDirect
            {
              pkg    = "tasty";
              ver    = "1.5.2";
              sha256 = "sha256-ikV62VQAAxsekESCxp7vldxopYiQGoYTCANsvGJlGcs="; #pkgs.lib.fakeSha256;
            }
            {});

        # ghc-lib-parser = hlib.markBroken old.ghc-lib-parser;
        # ghc-prof = hlib.doJailbreak old.ghc-prof;

        witherable = hlib.dontCheck
          (old.callHackage "witherable" "0.5" {});

        process = hlib.dontCheck
          (old.callHackage "process" "1.6.25.0" {});

        directory = hlib.dontCheck
          (old.callHackage "directory" "1.3.9.0" {});

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

    hpkgsFastTags = hpkgs910.extend (_: old:
      builtins.mapAttrs hutils.makeHaskellPackageAttribSmaller (old // {
        fast-tags = hlib.dontCheck (hlib.doJailbreak (old.callCabal2nix "fast-tags" fast-tags-repo {}));

        # Curse him who put os-string, a boot package, in the package set for
        # 9.10.1!
        #
        # Having boot package in here, e.g. containers, will create conflicts
        # when building packages that depend on it.
        #
        # Seriously, nix has pretty shitty parts and bullshit like
        # this can kill a few hours of your life like it’s nothing.
        #
        # Nix is great when it works, but when it doesn’t it’s a miserable
        # piece of FUCK.
        os-string            = null;

        vector               = hlib.dontCheck old.vector;
        async                = hlib.dontCheck old.async;
        alex                 = hlib.dontCheck old.alex;
        happy                = hlib.dontCheck old.happy;
        code-page            = hlib.dontCheck old.code-page;
        inspection-testing   = hlib.dontCheck old.inspection-testing;
        call-stack           = hlib.dontCheck old.call-stack;
        QuickCheck           = hlib.dontCheck old.QuickCheck;
        silently             = hlib.dontCheck old.silently;
        HUnit                = hlib.dontCheck old.HUnit;
        optparse-applicative = hlib.dontCheck old.optparse-applicative;
        hspec-expectations   = hlib.dontCheck old.hspec-expectations;
        pcre-light           = hlib.dontCheck old.pcre-light;
        file-io              = hlib.dontCheck old.file-io;
        syb                  = hlib.dontCheck old.syb;
        hspec-discover       = hlib.dontCheck old.hspec-discover;
        tasty-quickcheck     = hlib.dontCheck old.tasty-quickcheck;
        stringbuilder        = hlib.dontCheck old.stringbuilder;
        base-orphans         = hlib.dontCheck old.base-orphans;

        hashable             = hashable-pkg old;

        primitive            = hlib.dontCheck (old.callHackage "primitive" "0.9.0.0" {});
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
          nativeBuildInputs = [];
        }
          # ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}"
          ''
            mkdir -p "$out/bin"
            for x in ghc ghci ghc-pkg haddock hpc runghc; do
              # makeWrapper "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}" --suffix "LD_LIBRARY_PATH" ":" "${pkgs.lib.makeLibraryPath bakedInNativeDeps}"

              if [[ -f "${pkg}/bin/$x-${version}" ]]; then
                ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}"
              elif [[ -f "${pkg}/bin/$x-ghc-${version}" ]]; then
                ln -s "${pkg}/bin/$x-ghc-${version}" "$out/bin/$x-${version}"
              elif [[ -f "${pkg}/bin/$x" ]]; then
                ln -s "${pkg}/bin/$x" "$out/bin/$x-${version}"
              else
                echo "Cannot find source for ‘$x’ in ‘${pkg}/bin’" >&2
                exit 1
              fi

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

            for x in ghci ghc-pkg haddock hpc runghc; do

              if [[ -f "${pkg}/bin/$x-${version}" ]]; then
                ln -s "${pkg}/bin/$x-${version}" "$out/bin/$x-${version}"
              elif [[ -f "${pkg}/bin/$x-ghc-${version}" ]]; then
                ln -s "${pkg}/bin/$x-ghc-${version}" "$out/bin/$x-${version}"
              elif [[ -f "${pkg}/bin/$x" ]]; then
                ln -s "${pkg}/bin/$x" "$out/bin/$x-${version}"
              else
                echo "Cannot find source for ‘$x’ in ‘${pkg}/bin’" >&2
                exit 1
              fi

              ln -s "$out/bin/$x-${version}" "$out/bin/$x-${alias-version}"
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

    ghc-platform =
      { mkDerivation, base, lib
      # GHC source tree to build ghc-toolchain from
      , ghcSrc
      , ghcVersion
      }:
      mkDerivation {
        pname                 = "ghc-platform";
        version               = ghcVersion;
        src                   = ghcSrc;
        postUnpack            = ''sourceRoot="$sourceRoot/libraries/ghc-platform"'';
        libraryHaskellDepends = [base];
        description           = "Platform information used by GHC and friends";
        license               = lib.licenses.bsd3;
      };

    ghc-toolchain =
      { mkDerivation, base, directory, filepath, ghc-platform, lib
      , process, text, transformers
      # GHC source tree to build ghc-toolchain from
      , ghcVersion
      , ghcSrc
      }:
      mkDerivation {
        pname                 = "ghc-toolchain";
        version               = ghcVersion;
        src                   = ghcSrc;
        postUnpack            = ''sourceRoot="$sourceRoot/utils/ghc-toolchain"'';
        libraryHaskellDepends = [base directory filepath ghc-platform process text transformers];
        description           = "Utility for managing GHC target toolchains";
        license               = lib.licenses.bsd3;
      };

    build-ghc = { base-ghc-to-override, build-pkgs, version, rev, sha256 }:
      let ghcSrc = pkgs.fetchgit {
            url = "https://gitlab.haskell.org/ghc/ghc.git";
            inherit rev sha256;
          };
          ghc' = base-ghc-to-override.override (old: old // {
            bootPkgs = build-pkgs;
            inherit ghcSrc;
          });

          callPackage' = f: args: build-pkgs.callPackage f ({
            inherit ghcSrc;
            ghcVersion = version;
          } // args);

          ghc-platform-pkg  = callPackage' ghc-platform {};
          ghc-toolchain-pkg = callPackage' ghc-toolchain { ghc-platform = ghc-platform-pkg; };

      in
        disableAllHardening (hutils.smaller-ghc ((ghc'.override (old: old // {
          bootPkgs = build-pkgs;
          hadrian  = hlib.doJailbreak (ghc'.hadrian.override (old2: old2 // {
            inherit ghcSrc;
            ghc-platform  = hutils.makeHaskellPackageSmaller ghc-platform-pkg;
            ghc-toolchain = hutils.makeHaskellPackageSmaller ghc-toolchain-pkg;
            ghcVersion    = version;
          }));
          inherit ghcSrc;
        })).overrideAttrs (old: {
          inherit version;

          postInstall =
            builtins.replaceStrings [ base-ghc-to-override.version ] [ "${version}" ] old.postInstall;

          preConfigure = old.preConfigure +
            # builtins.replaceStrings [ base-ghc-to-override.version ] [ "${version}" ] old.preConfigure +

            # Do this if taking sources from git directly.
            ''
              echo ${version} > VERSION
              echo ${rev} > GIT_COMMIT_ID
              ./boot
            '';
        })));

    # ghc9121 = build-ghc {
    #   base-ghc-to-override = pkgs.haskell.compiler.ghc9101;
    #   build-pkgs           = hpkgsCabal; #pkgs.haskell.packages.native-bignum.ghc9101;
    #   version              = "9.12.1";
    #   rev                  = "daf659b6e3c8f2a84100fbee797cd9d457c00df5";
    #   sha256               = "sha256-oSiGEkiQlkmCr7qsFUJ9qpwsU4AumOIpFn6zN4ByMNg="; #pkgs.lib.fakeSha256;
    # };

    filter-bin = name: keep-these: pkg:
      assert (builtins.isList keep-these);
      let f = { source, dest, aliases }:
            assert builtins.isString source;
            assert builtins.isString dest;
            assert builtins.isList aliases && builtins.all builtins.isString aliases;
            ''
              if [[ ! -e "${pkg}/bin/${source}" ]]; then
                 echo "Source file '${source}' does not exist within package ${pkg}" >&2
                 exit 1
              fi
              ln -s "${pkg}/bin/${source}" "$out/bin/${dest}"
              ${builtins.concatStringsSep "\n" (builtins.map (a: ''ln -s "$out/bin/${dest}" "$out/bin/${a}"'') aliases)}
            '';
      in
        pkgs.runCommand ("filtered-" + name) {
          nativeBuildInputs = [];
        }
          ''
            mkdir -p "$out/bin"
            ${builtins.concatStringsSep "\n" (builtins.map f keep-these)}
          '';

    cabal-install = wrap-cabal (hlib.justStaticExecutables hpkgsCabal.cabal-install);

    ghc-win =
      let
        # Defines ‘x86_64-w64-mingw32-ghc’, ‘x86_64-w64-mingw32-ghc-pkg’, and ‘x86_64-w64-mingw32-hsc2hs,
        win-pkgs = pkgs-cross-win.pkgsCross.mingwW64;

        ghc-win  = win-pkgs.pkgsBuildHost.haskell-nix.compiler.ghc9101; # pkgsBuildHost == buildPackages

        wine-iserv-wrapper-script =
          let
            exes                    = win-pkgs.haskell-nix.iserv-proxy-exes.ghc9101;
            iserv-proxy             = exes.iserv-proxy;
            iserv-proxy-interpreter = exes.iserv-proxy-interpreter.override (old: {
              # Without these flags the executable with fail with error
              # Mingw-w64runtimefailure:
              # 32 bit pseudo relocation at 00000001401203C6 out of range, targeting 0000000000468160, yielding the value FFFFFFFEC0347D96.
              setupBuildFlags = ["--ghc-option=-optl-Wl,--disable-dynamicbase,--disable-high-entropy-va,--image-base=0x400000" ];
            });
            exe-name                = iserv-proxy-interpreter.exeName;
            # win-pkgs.windows.pthreads - not needed
            dllPkgs = [
              # win-pkgs.libffi
              # win-pkgs.gmp
              # win-pkgs.windows.mcfgthreads
              # win-pkgs.windows.mingw_w64_pthreads
              # win-pkgs.buildPackages.gcc.cc
            ];
          in
            pkgs.pkgsBuildBuild.writeScriptBin "iserv-wrapper"
              ''
                #!${pkgs-cross-win.pkgsBuildBuild.bash}/bin/bash

                set -euo pipefail

                function is_port_open() {
                    let port="$1"
                    # Native bash way to test ports.
                    true &>/dev/null </dev/tcp/127.0.0.1/$port && return 0 || return 1
                }

                # May lead to a too large environment so best to unset it.
                unset configureFlags

                PORT=$((5000 + $RANDOM % 5000))

                while is_port_open "$PORT"; do
                    PORT=$((5000 + $RANDOM % 5000))
                done

                REMOTE_ISERV=/tmp/iserv-tmpdir
                if [[ ! -d "$REMOTE_ISERV" ]]; then
                    mkdir -p "$REMOTE_ISERV/tmp"
                    ln -s ${iserv-proxy-interpreter}/bin/*.dll "$REMOTE_ISERV"

                    for p in ${pkgs.lib.concatStringsSep " " dllPkgs}; do
                        find "$p" -iname '*.dll' -exec ln -sf {} $REMOTE_ISERV \;
                        find "$p" -iname '*.dll.a' -exec ln -sf {} $REMOTE_ISERV \;
                    done

                    # Some DLLs have a `lib` prefix but we attempt to load them without the prefix.
                    # This was a problem for `double-conversion` package when used in TH code.
                    # Creating links from the `X.dll` to `libX.dll` works around this issue.
                    for dll in "$REMOTE_ISERV"/*.dll; do
                        small=$(basename "$dll")
                        ln -s "$dll" "$REMOTE_ISERV/''${small#lib}"
                    done

                fi
                (
                    WINEDLLOVERRIDES="winemac.drv=d" \
                        WINEDEBUG="warn-all,fixme-all,-menubuilder,-mscoree,-ole,-secur32,-winediag" \
                        WINEPREFIX="$REMOTE_ISERV/prefix" \
                        ${pkgs-cross-win.winePackages.minimal}/bin/wine64 \
                        ${iserv-proxy-interpreter}/bin/${exe-name} \
                        "$REMOTE_ISERV/tmp" \
                        "$PORT" ) &
                PID="$!"
                ${iserv-proxy}/bin/iserv-proxy "''${@}" 127.0.0.1 "$PORT"
                kill "$PID"
              '';

        wine-run-haskell =
          let dll-path =
                win-pkgs.lib.strings.concatStringsSep
                  ";"
                  (
                    map (x: "${x}/bin") [win-pkgs.libffi win-pkgs.gmp win-pkgs.windows.mcfgthreads] ++
                    map (x: "${x}/lib") [win-pkgs.buildPackages.gcc.cc.lib]
                  );
          in pkgs-cross-win.pkgsBuildBuild.writeShellApplication {
            name          = "wine-run-haskell";
            runtimeInputs = [
            ];
            text          =
              ''
                WINEDLLOVERRIDES="winemac.drv=d" \
                    WINEDEBUG="-all" \
                    WINEPATH="${dll-path};''${WINEPATH:-}" \
                    ${pkgs-cross-win.winePackages.minimal}/bin/wine64 \
                    "''${@}"
              '';
          };

        # "-L${mingw_w64_pthreads}/lib"
        # "-L${mingw_w64_pthreads}/bin"
        # "-L${gmp}/lib"
        wrap-win-ghc = pkg: ghc-exe: new-name:
          pkgs-cross-win.pkgsBuildBuild.writeShellApplication {
            name          = new-name;
            runtimeInputs = [
              pkg
              # So that ghc and its subcommands will be able to run ‘x86_64-w64-mingw32-gcc’
              win-pkgs.buildPackages.gcc.cc
            ];
            # "-L${win-pkgs.libffi}/bin" \
            # "-L${win-pkgs.libffi}/lib" \
            # "-L${win-pkgs.gmp}/bin" \
            # "-L${win-pkgs.gmp}/lib" \
            text          =
              ''
                ${pkg}/bin/${ghc-exe} \
                  -fexternal-interpreter \
                  -pgmi ${wine-iserv-wrapper-script}/bin/iserv-wrapper \
                  "-L${win-pkgs.windows.mingw_w64_pthreads}/lib" \
                  "-L${win-pkgs.windows.mingw_w64_pthreads}/bin" \
                  "-L${win-pkgs.windows.mcfgthreads}/bin" \
                  "-L${win-pkgs.windows.mcfgthreads}/lib" \
                  "''${@}"
              '';
          };

        wrap-win-ghc-pkg = pkg: exe: new-name:
          pkgs-cross-win.pkgsBuildBuild.writeShellApplication {
            name          = new-name;
            runtimeInputs = [pkg];
            text          =
              ''
                ${pkg}/bin/${exe} "''${@}"
              '';
          };

        wrap-win-hsc2hs = pkg: exe: new-name:
          pkgs-cross-win.pkgsBuildBuild.writeShellApplication {
            name          = new-name;
            runtimeInputs = [pkg];
            text          =
              ''
                ${pkg}/bin/${exe} --cross-compile --via-asm "''${@}"
              '';
          };

        ghc-win-wrapped = wrap-win-ghc ghc-win "x86_64-w64-mingw32-ghc" "ghc-9.10-win";
        ghc-pkg-win-wrapped = wrap-win-ghc-pkg ghc-win "x86_64-w64-mingw32-ghc-pkg" "ghc-pkg-9.10-win";
        hsc2hs-win-wrapped = wrap-win-hsc2hs ghc-win "x86_64-w64-mingw32-hsc2hs" "hsc2hs-9.10-win";

        cabal-win-wrapped =
          # builtins.trace ("ghc-win-wrapped.name = " + builtins.toString ghc-win-wrapped.name)
          # (builtins.trace (builtins.toString (builtins.attrNames win-pkgs.buildPackages.binutils))
          #   ghc-win-wrapped);
          pkgs-cross-win.pkgsBuildBuild.writeShellApplication {
            name          = "cabal-win";
            runtimeInputs = [
              cabal-install
              ghc-win-wrapped
              ghc-pkg-win-wrapped
              hsc2hs-win-wrapped
              # For x86_64-w64-mingw32-ld
              win-pkgs.buildPackages.binutils
            ];
            text          =
              ''
                cmd="$1"
                shift
                CABAL_DIR=~/.cabal-win cabal "$cmd" \
                  --with-compiler ${ghc-win-wrapped.name} \
                  --with-hc-pkg ${ghc-pkg-win-wrapped.name} \
                  --with-hsc2hs ${hsc2hs-win-wrapped.name} \
                  --with-ld "x86_64-w64-mingw32-ld" \
                  "''${@}"
              '';
          };
      in {
        inherit ghc-win-wrapped ghc-pkg-win-wrapped hsc2hs-win-wrapped wine-run-haskell cabal-win-wrapped;
      };

in ghc-win // {

  ghc7103     = wrap-ghc-filter-all               "7.10.3" "7.10"        pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc7103.ghc;
  ghc802      = wrap-ghc-filter-hide-source-paths "8.0.2"  "8.0"         pinned-pkgs.nixpkgs-18-09.haskell.packages.ghc802.ghc;

  ghc822      = wrap-ghc                          "8.2.2"  "8.2"         pinned-pkgs.nixpkgs-19-09.haskell.packages.ghc822.ghc;
  ghc844      = wrap-ghc                          "8.4.4"  "8.4"         pinned-pkgs.nixpkgs-20-03.haskell.packages.ghc844.ghc;

  ghc865      = wrap-ghc                          "8.6.5"  "8.6"         pinned-pkgs.nixpkgs-20-09.haskell.packages.ghc865.ghc;

  ghc884      = wrap-ghc                          "8.8.4"  "8.8"         pinned-pkgs.nixpkgs-23-11.haskell.packages.ghc884.ghc;

  ghc8107     = wrap-ghc                          "8.10.7" "8.10"        pinned-pkgs.nixpkgs-23-11.haskell.packages.ghc8107.ghc;
  # ghc902    = wrap-ghc                          "9.0.2"  "9.0"         (hutils.smaller-ghc pinned-pkgs.nixpkgs-23-11.haskell.packages.ghc902.ghc);
  ghc928      = wrap-ghc                          "9.2.8"  "9.2"         pinned-pkgs.nixpkgs-23-11.haskell.packages.ghc928.ghc;
  ghc948      = wrap-ghc                          "9.4.8"  "9.4"         pinned-pkgs.nixpkgs-23-11.haskell.packages.ghc948.ghc;

  ghc966      = wrap-ghc                          "9.6.6"  "9.6"         pkgs.haskell.compiler.native-bignum.ghc966;
  ghc982      = wrap-ghc                          "9.8.2"  "9.8"         pkgs.haskell.compiler.native-bignum.ghc982;

  ghc9101     = wrap-ghc                          "9.10.1" "9.10"        pkgs.haskell.compiler.native-bignum.ghc9101;

  ghc9121     = wrap-ghc                          "9.12.1" ["9.12" null] pkgs.haskell.compiler.native-bignum.ghc9121;

  ghc9121-pie = wrap-ghc-rename                   "9.12.1" "9.12-pie"    (relocatable-static-libs-ghc pkgs.haskell.compiler.native-bignum.ghc9121);

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

  inherit cabal-install;

  alex               = hlib.justStaticExecutables hpkgs910.alex;
  happy              = hlib.justStaticExecutables hpkgs910.happy;
  doctest            = allowGhcReference (hlib.justStaticExecutables hpkgsDoctest.doctest);
  eventlog2html      = hlib.justStaticExecutables hpkgsEventlog2html.eventlog2html;
  fast-tags          = hlib.justStaticExecutables hpkgsFastTags.fast-tags;
  ghc-events-analyze = hlib.justStaticExecutables hpkgsGhcEvensAnalyze.ghc-events-analyze;
  hp2pretty          = hlib.justStaticExecutables hpkgs96.hp2pretty;
  pretty-show        = hlib.justStaticExecutables hpkgs96.pretty-show;
  profiterole        = hlib.justStaticExecutables hpkgsProfiterole.profiterole;
  # hspec-discover     = hlib.justStaticExecutables hpkgs96.hspec-discover;
  # threadscope        = threadscopePkgs.threadscope;
  universal-ctags    = pkgs.universal-ctags;

  gcc  = pkgs.gcc;
  # Conflicts with gcc regarding ld.gold
  # clang = pkgs.clang_19;
  llvm = pkgs.llvm_19;
  # bintools = pkgs.llvmPackages_19.bintools;
  # lld   = pkgs.lld_19;
  lld  = filter-bin "llvmPackages_19.bintools" [{ source = "ld"; dest = "lld"; aliases = ["ld.lld"]; }] pkgs.llvmPackages_19.bintools;

  # for ‘clang-format’
  clang-tools = pkgs.clang-tools;
  cmake       = pkgs.cmake;
  diffutils   = pkgs.diffutils;
  gdb         = pkgs.gdb;
  gnumake     = pkgs.gnumake;
  libtree     = pkgs.libtree;
  patchelf    = pkgs.patchelf;
  pkg-config  = pkgs.pkg-config;
}

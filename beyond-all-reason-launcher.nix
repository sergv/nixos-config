{ lib
, stdenv
, fetchFromGitHub
, buildNpmPackage
, runCommand
, nodejs
, electron
, butler
, steam-run
, jq
, xorg
, libcxx

  # dependencies for pr-downloader
, gcc
, cmake
, curl
, pkg-config
, jsoncpp
, boost
, minizip
}:

# This builds the launcher for Beyond All Reason.
# Which can then download the engine, the lobby, and the game.
# Starts the launcher with steam-run, so that the game starts without further
# patching.

let
  version = "1.2470.0"; #"1.2124.0"; # 1.1861.0
  srcs = {
    # Contains the configuration for the launcher.
    byar-chobby = fetchFromGitHub {
      owner  = "beyond-all-reason";
      repo   = "BYAR-Chobby";
      rev    = "v${version}";
      sha256 = "sha256-evIoYuw+1Ma98oBYQ6wSKXSpyt45/wODUP4YSHvI37w="; # lib.fakeSha256;
    };
      # fetchzip {
      # url  = "https://github.com/beyond-all-reason/BYAR-Chobby/archive/refs/tags/v${version}.zip";
      # hash = lib.fakeSha256;
    # };

    spring-launcher = fetchFromGitHub {
      owner  = "beyond-all-reason";
      repo   = "spring-launcher";
      rev    = "2c6e0a63d317b5fc5f92ee39742e1f8a55c41976"; # "c625661330bfdc6e3a6757e4a65e6d5402f1d00a"; # "439a9b7b7d835691267ad13586d0efc763d39b60";
      sha256 = "sha256-YhZqckkIs4SHlCgJkSHTHRyI2Bc3mRMZN9+Wwx70lzM="; # lib.fakeSha256;
    };
  };

  # From: https://github.com/beyond-all-reason/BYAR-Chobby/blob/1ee341043b6bb1f488ed5aab5d02c85018c572ed/.github/workflows/launcher.yml
  src = runCommand "byar-launcher-src-${version}"
    {
      buildInputs = [ nodejs jq ];
    } ''
    cp -r ${srcs.byar-chobby} BYAR-Chobby
    cp -r ${srcs.spring-launcher} launcher
    chmod -R +w *

    echo --- Patch launcher with dist_cfg
    cp -r BYAR-Chobby/dist_cfg/* launcher/src/
    for dir in bin files build; do
      mkdir -p launcher/$dir
      if [ -d launcher/src/$dir/ ]; then
        mv launcher/src/$dir/* launcher/$dir/
        rm -rf launcher/src/$dir
      fi
    done

    echo --- Make package.json
    GITHUB_REPOSITORY=beyond-all-reason/BYAR-Chobby
    cd BYAR-Chobby
    export PACKAGE_VERSION=${version}
    echo "Making build for version: $PACKAGE_VERSION"
    node build/make_package_json.js ../launcher/package.json dist_cfg/config.json $GITHUB_REPOSITORY $PACKAGE_VERSION
    cd ..

    echo --- Patching package.json
    # Rebuilding electron would fail: It tries to access github.com.
    # And we do not need it anyway.
    jq 'del(.devDependencies.electron)' launcher/package.json > temp
    mv temp launcher/package.json
    jq 'del(.packages."".devDependencies.electron)' launcher/package-lock.json \
      | jq 'del(.packages."node_modules/electron")' > temp
    mv temp launcher/package-lock.json

    echo --- Force dev mode to prevent launcher-update
    sed -i 's/const isDev = .*\;/const isDev = true\;/' launcher/src/launcher_wizard.js

    mv launcher $out
  '';

  # If building this fails or stucks, try building with NIX_BUILD_CORES=1 instead.
  # Downloading npm dependencies with multiple cores is prone to hanging.
  nodeModules = buildNpmPackage {
    inherit src version;
    pname = "byar-launcher-package";
    npmDepsHash = "sha256-dbURtLbgprljQaxurnAscydGHt3ORtd18lktVeY+iQU="; #"sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # "sha256-CKBdeIGplXSM/OP9+igmLWR/FC2xnwAAhbYwlTp8ZSY="; # "sha256-cCUtkycZ0bpLwcCfBjf+rTeoMHN7jIxcYCtyrB4rC8A=";
    npmFlags = [ "--legacy-peer-deps" ];
    dontNpmBuild = true;
    passthru = {
      buildInputs = [
        nodejs
        libcxx
        xorg.libX11
      ];
    };
    installPhase = ''
      mv node_modules $out
    '';
  };

  pr-downloader = stdenv.mkDerivation rec {
    pname = "pr-downloader";
    version = "master";
    src = fetchFromGitHub {
      owner = "beyond-all-reason";
      repo = "pr-downloader";
      rev = "4e30e3e776c47b81e790fffcb2b62f81437e0c24"; # "d3ad0156fe1c9123b32f966c00ed3825e62ae15d"; #"79b605d013a0c5a92090b3892e8e0c0aeccac2a8";
      sha256 = "sha256-nHFGhgiWBPJUQe120TQn52FoPDA50U5EW3PKeh/OLVs="; # lib.fakeSha256; # "sha256-ckDt8cG9fktej3A5xSDZmenn6u1N6pWayqnsLrQVeno="; #"sha256-noroFiv2wAUCgI1ne2sP0PVBxIf20D+m5oa5+pk2OXQ=";
      fetchSubmodules = true;
    };
    buildInputs = [
      gcc
      cmake
      curl
      pkg-config
      jsoncpp
      boost
      minizip
    ];
    postInstall = ''
      mkdir $out/bin
      mv $out/pr-downloader $out/bin
    '';
  };
in
stdenv.mkDerivation {
  inherit src version;
  pname = "byar-launcher";
  phases = [ "buildPhase" ];
  buildPhase = ''
    mkdir -p $out/lib/dist
    cp -r $src/* $out/lib/dist
    chmod -R +w $out/lib/dist

    cp -r ${nodeModules} $out/lib/dist/node_modules

    rm $out/lib/dist/bin/butler/linux/butler
    ln -s ${butler}/bin/butler $out/lib/dist/bin/butler/linux/butler

    rm $out/lib/dist/bin/pr-downloader
    ln -s ${pr-downloader}/bin/pr-downloader $out/lib/dist/bin/pr-downloader

    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/byar-launcher
    echo "${steam-run}/bin/steam-run ${electron}/bin/electron $out/lib/dist" >> $out/bin/byar-launcher
    chmod +x $out/bin/byar-launcher
  '';
}

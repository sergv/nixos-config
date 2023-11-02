#!/bin/sh
#
# File: long-rebuild.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u

if [[ "$EUID" != 0 ]] ; then
  echo "This must be run as root!"
  exit 1
fi

export TMPDIR=/tmp/nix-daemon
export TEMPDIR=/tmp/nix-daemon

export NIX_BUILD_CORES="8"
export NINJAFLAGS="-j8 -l8"

nixos-rebuild build --flake .#home --verbose --max-jobs 2 --cores 16 --keep-going "${@}"
# # Consider this instead because things like qtwebkit can require around 40gb of RAM (on 32 cores, perhaps less is better).
# nixos-rebuild build --flake .#home --verbose --max-jobs 1 --cores 32 --keep-going "${@}"

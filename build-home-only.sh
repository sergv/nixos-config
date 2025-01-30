#! /usr/bin/env bash
#
# File: build-home-only.sh
#
# Created: 30 January 2025
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

export NIX_BUILD_CORES="16"
export NINJAFLAGS="-j16 -l16"

nix build .#homeManagerConfigurations.sergey.activationPackage --out-link /tmp/nixos-rebuild-result/result --verbose -j2 --cores 16 --keep-going "${@}"

exit 0


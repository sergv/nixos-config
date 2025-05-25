#! /usr/bin/env bash
#
# File: build.sh
#
# Created: 19 November 2023
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

export NIX_BUILD_CORES="8"
export NINJAFLAGS="-j8 -l8"

nix build .#nixosConfigurations."home".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result --verbose -j2 --cores 8 --keep-going "${@}"

# exec ./apply-system.sh build "${@}"


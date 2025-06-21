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

export NIX_BUILD_CORES="16"
export NINJAFLAGS="-j16 -l16"

nix build .#nixosConfigurations."home".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result --verbose -j2 --cores 16 --keep-going "${@}"

# exec ./apply-system.sh build "${@}"


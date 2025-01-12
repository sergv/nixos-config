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

export NIX_BUILD_CORES="4"
export NINJAFLAGS="-j4 -l4"

nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#nixosConfigurations."work-wsl".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result --verbose -j2 --cores 10 --keep-going "${@}"

# exec ./apply-system.sh build "${@}"


#! /usr/bin/env bash
#
# File: build-system-debug.sh
#
# Created: 30 August 2023
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

export NIX_BUILD_CORES="10"
export NINJAFLAGS="-j10 -l10"

nix build --no-eval-cache .#nixosConfigurations."work-wsl".config.system.build.toplevel --show-trace --refresh --out-link /tmp/nixos-rebuild-result/result --verbose -j2 --cores 16 --keep-going "${@}"


exit 0


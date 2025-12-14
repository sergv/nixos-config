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

# ssh-agent
# ssh-add /home/sergey/.ssh/nix-cache-ro.key
# --option extra-substituters ssh://nix-ssh@192.168.1.226?trusted=true

nix build .#nixosConfigurations."home".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result --verbose -j2 --cores 16 --keep-going "${@}"

# exec ./apply-system.sh build "${@}"


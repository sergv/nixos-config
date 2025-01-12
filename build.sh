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

export NIX_BUILD_CORES="10"
export NINJAFLAGS="-j10 -l10"

nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#nixosConfigurations."work-wsl".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result --verbose --max-jobs 4 --cores 10 --keep-going "${@}"

# ssh-agent
# ssh-add /home/sergey/.ssh/nix-cache-ro.key
# --option extra-substituters ssh://nix-ssh@192.168.1.226?trusted=true

# exec ./apply-system.sh build "${@}"


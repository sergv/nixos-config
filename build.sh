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

nix build .#nixosConfigurations."home".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result "${@}"

# exec ./apply-system.sh build "${@}"


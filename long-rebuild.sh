#! /usr/bin/env bash
#
# File: long-rebuild.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

[[ ! -v TMPDIR ]] && export TMPDIR=/tmp/nix-daemon
[[ ! -v TEMPDIR ]] && export TEMPDIR=/tmp/nix-daemon

export ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export NIX_BUILD_JOBS=1
"$ROOT/build.sh" "${@}"


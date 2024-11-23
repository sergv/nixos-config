#!/bin/sh
#
# File: apply-system.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u

if [[ "$EUID" != 0 ]] ; then
  echo "This must be run as root!" >&2
  exit 1
fi

if [[ "$#" == 0 ]] ; then
  echo "usage: $0 [nixos-rebuild command]" >&2
  exit 1
fi

export TMPDIR=/tmp/nix-daemon
export TEMPDIR=/tmp/nix-daemon

jobs="1"
export NIX_BUILD_CORES="2"
export NINJAFLAGS="-j2 -l2"

command="$1"
shift

# force nixos-rebuild to use nix-daemon
# NIX_REMOTE=daemon

# --verbose
nixos-rebuild "${command}" --flake .#home --keep-going --cores 1 --max-jobs 1 "${@}"

# nixos-rebuild build --flake .#home --verbose --keep-going "${@}"
# nixos-rebuild test --flake .#home --verbose --keep-going "${@}"
#nixos-rebuild switch --flake .#home --verbose --keep-going "${@}"
# strace -f -e execve nixos-rebuild boot --flake .#home --verbose --keep-going "${@}"
#nixos-rebuild boot --flake .#home --verbose --keep-going --max-jobs "$jobs" "${@}"

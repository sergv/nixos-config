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

command="$1"
shift

# force nixos-rebuild to use nix-daemon
# NIX_REMOTE=daemon

system_name="home"
jobs="1"
cores="2"
export NIX_BUILD_CORES="$cores"
export NINJAFLAGS="-j$cores -l$cores"

# --verbose
nixos-rebuild "${command}" --flake ".#${system_name}" --keep-going --cores "$cores" --max-jobs "$jobs" "${@}"

# nixos-rebuild build --flake .#home --verbose --keep-going "${@}"
# nixos-rebuild test --flake .#home --verbose --keep-going "${@}"
#nixos-rebuild switch --flake .#home --verbose --keep-going "${@}"
# strace -f -e execve nixos-rebuild boot --flake .#home --verbose --keep-going "${@}"
#nixos-rebuild boot --flake .#home --verbose --keep-going --max-jobs "$jobs" "${@}"

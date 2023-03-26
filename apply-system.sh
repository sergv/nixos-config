#!/bin/sh
#
# File: apply-system.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u

if [[ "$EUID" != 0 ]] ; then
  echo "This must be run as root!"
  exit 1
fi

nixos-rebuild switch --flake .#home

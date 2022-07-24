#!/bin/sh
#
# File: apply-system.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u

nixos-rebuild switch --flake .#home

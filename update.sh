#!/bin/sh
#
# File: update.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u

nix flake update --recreate-lock-file

exit 0


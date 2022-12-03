#!/bin/sh
#
# File: apply-user.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u

set -e

nix build --print-build-logs .#homeManagerConfigurations.sergey.activationPackage "${@}"
./result/activate

exit 0


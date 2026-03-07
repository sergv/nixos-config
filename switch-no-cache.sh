#! /usr/bin/env bash
#
# File: switch-no-cache.sh
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

set -e

exec ./apply-system.sh switch --option substitute false

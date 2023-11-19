#! /usr/bin/env bash
#
# File: test.sh
#
# Created: 19 November 2023
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

exec ./apply-system.sh test "${@}"


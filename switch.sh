#! /usr/bin/env bash
#
# File: boot.sh
#
# Created: Sunday, 30 August 2026
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

exec ./apply-system.sh switch "${@}"


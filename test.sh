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

# Work around KDE turning this symlink into non-symlink and breaking
# update. Bullshsit opinionated stuff that cannot follow user’s
# intentions, read the fucking room, KDE.
rm -f /home/sergey/.local/share/recently-used.xbel

exec ./apply-system.sh test "${@}"


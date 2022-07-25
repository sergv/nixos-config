#! /bin/sh
#
# File: wm.sh
#
# Created: 24 July 2022
#

# treat undefined variable substitutions as errors
set -u
set -e

err() {
    echo "$1" >&2
    exit 1
}

if [ "$#" -ne 1 -a "$#" -ne 2 ]; then
  err "usage: $0 COMMAND [ARG]"
fi

command="$1"

last_workspace_file="/tmp/last-workspace"

current_desktop=$(wmctrl -d | awk '/^[0-9]+ +\*/ { print $1 }')

[ -z "$current_desktop" ] && err "Cannot determine current desktop"

case "$command" in
    "switch" )
        if [ "$#" -ne 2 ]; then
          err "usage: $0 switch WORKSPACE-NUMBER"
        fi
        dest="$2"
        [ -z "$dest" ] && err "Empty destination to switch to: '$dest'"
        wmctrl -s "$dest"
        echo "$current_desktop" > "$last_workspace_file"
        ;;
    # "pop" )
    #     ;;
    "swap" )
        if [ -f "$last_workspace_file" ]; then
            dest=$(cat "$last_workspace_file")
            [ -z "$dest" ] && err "Empty destination to swap with: '$dest'"
            wmctrl -s "$dest"
            echo "$current_desktop" > "$last_workspace_file"
        else
            err "No last workspace to swap with"
        fi
        ;;
    "forward" )
        workspace_count=$(wmctrl -d | wc -l)
        dest="$(( ($current_desktop + 1) % $workspace_count ))"
        wmctrl -s "$dest"
        echo "$current_desktop" > "$last_workspace_file"
        ;;
    "backward" )
        workspace_count=$(wmctrl -d | wc -l)
        dest="$(( ($current_desktop - 1) % $workspace_count ))"
        if [ "$dest" -lt 0 ]; then
            dest="$(( $dest + $workspace_count ))"
        fi
        wmctrl -s "$dest"
        echo "$current_desktop" > "$last_workspace_file"
        ;;
    * )
        err "Invalid command: '$command'"
        ;;
esac

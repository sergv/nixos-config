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
    "move-active-to" )
        if [ "$#" -ne 2 ]; then
          err "usage: $0 move-active-to WORKSPACE-NUMBER"
        fi
        dest="$2"
        [ -z "$dest" ] && err "Empty destination to move to: '$dest'"

        count_windows_on_current=$(wmctrl -l | awk 'BEGIN { s = 0 }; $2 == '"$current_desktop"' { s += 1; } END { print s; }')
        if [ "$count_windows_on_current" -ne 0 ]; then
            wmctrl -r :ACTIVE: -t "$dest"
        else
            err "No active window"
        fi
        ;;
    * )
        err "Invalid command: '$command'"
        ;;
esac

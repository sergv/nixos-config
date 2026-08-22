#! /usr/bin/env bash
#
# File: build.sh
#
# Created: 19 November 2023
#

# treat undefined variable substitutions as errors
set -u
# propagate errors from all parts of pipes
set -o pipefail

export NIX_BUILD_CORES="16"
export NINJAFLAGS="-j16 -l16"

# ssh-agent
# ssh-add /home/sergey/.ssh/nix-cache-ro.key
# --option extra-substituters ssh://nix-ssh@192.168.1.226?trusted=true

# nix build .#nixosConfigurations."wsl".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result --verbose -j4 --cores 16 --keep-going "${@}"

declare -a targets
declare -a opts
targets=()
opts=()

for x in "${@}"; do
    case "$x" in
        "macbook" )
            targets+=(".#darwinConfigurations.\"${x}\".config.system.build.toplevel")
            ;;
        "home" | "wsl" )
            targets+=(".#nixosConfigurations.\"${x}\".config.system.build.toplevel")
            ;;
        * )
            opts+=("$x")
            ;;
    esac
done

if [[ "${#targets[@]}" == 0 ]]; then
    echo "No targets" >&2
    exit 1
fi

cores="1"
if [[ -v NIX_BUILD_CORES ]]; then
    cores="$NIX_BUILD_CORES"
else
    cores="$(getconf _NPROCESSORS_ONLN)"
    if [[ "$OSTYPE" == "linux-gnu" ]] && command -v lscpu >/dev/null 2>&1; then
        threads_per_core=$(lscpu | awk '/^ *Thread\(s\) per core:/ { print $NF; }')
        cores=$(( "$cores" / "$threads_per_core" ))
        # cores=$(lscpu | awk 'BEGIN { cores = 0; threads = 0; } /^ *CPU\(s\):/ { cores = $NF; } /^ *Thread\(s\) per core:/ { threads = $NF; } END { print (cores / threads); }')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        cores="$cores"
        # cores=$(sysctl machdep.cpu.core_count | cut -w -f2)
    elif [[ -e /proc/cpuinfo ]]; then
        cores="$(awk '/processor/' /proc/cpuinfo | wc -l)"
    fi
fi

nix build --out-link /tmp/nixos-rebuild-result/result --verbose -j4 --cores "$cores" --keep-going "${targets[@]}" "${opts[@]}"


# trix build .#nixosConfigurations."home".config.system.build.toplevel --out-link /tmp/nixos-rebuild-result/result -j2 --cores 16 --keep-going "${@}" "${@}"


# exec ./apply-system.sh build "${@}"


#!/bin/bash

set -euo pipefail

CONFIG_DIR="/etc/wireguard"
STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/assets/vpn-state"

mkdir -p "$(dirname "$STATE_FILE")"
[[ ! -f "$STATE_FILE" ]] && echo -n "none" > "$STATE_FILE"

list_configs() {
    ls "$CONFIG_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/\.conf$//'
}

get_next_config() {
    local current="$1"
    shift
    local configs=("$@")
    for i in "${!configs[@]}"; do
        [[ "${configs[$i]}" == "$current" ]] && echo "${configs[((i + 1) % ${#configs[@]})]}" && return
    done
    echo "${configs[0]}"
}

CURRENT="$(<"$STATE_FILE")"
[[ -z "$CURRENT" ]] && CURRENT="none"

readarray -t CONFIGS < <(list_configs)

case "${1:-}" in
    "right")
        NEXT="$(get_next_config "$CURRENT" "${CONFIGS[@]}")"
        [[ "$CURRENT" != "none" ]] && sudo wg-quick down "$CURRENT"
        sudo wg-quick up "$NEXT"
        echo -n "$NEXT" > "$STATE_FILE"
        ;;
    "left")
        if [[ "$CURRENT" != "none" ]]; then
            if sudo wg show interfaces | grep -Fxq "$CURRENT"; then
                sudo wg-quick down "$CURRENT"
            else
                sudo wg-quick up "$CURRENT"
            fi
        fi
        ;;
    *)
        if [[ "$CURRENT" == "none" ]]; then
            echo "No config selected"
        else
            if sudo wg show interfaces | grep -Fxq "$CURRENT"; then
                echo "   $CURRENT "
            else
                echo "   $CURRENT "
            fi
        fi
        ;;
esac

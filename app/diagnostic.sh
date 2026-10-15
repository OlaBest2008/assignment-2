#!/usr/bin/env bash

usage() {
    cat << 'EOF'
Usage: diagnostic <command> [options]

Commands:
  system            Display Linux system information
  network <host>    Perform host resolution and basic connectivity checks
  disk              Display disk usage information
  help              Display commands and usage guidance

Exit Codes:
  0  Success
  1  Operational / runtime failure
  2  Invalid command or argument
EOF
}

cmd_system() {
    echo "=========================================="
    echo "          SYSTEM DIAGNOSTICS              "
    echo "=========================================="
    echo "Hostname:         $(hostname)"
    echo "Operating System: $(uname -s)"
    echo "Kernel Version:   $(uname -r)"
    echo "Uptime:           $(uptime -p 2>/dev/null || uptime)"
    echo "Architecture:     $(uname -m)"
    echo "Memory Summary:   $(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}' || echo "N/A")"
    echo "Current Working Dir: $(pwd)"
    echo "=========================================="
    exit 0
}

cmd_network() {
    local host="${1:-}"
    if [ -z "$host" ]; then
        echo "Error: Network command requires a target hostname or IP." >&2
        usage
        exit 2
    fi

    echo "=========================================="
    echo "         NETWORK DIAGNOSTICS              "
    echo "=========================================="
    echo "Target Host: $host"

    local resolved_ip=""
    if command -v getent >/dev/null 2>&1; then
        resolved_ip=$(getent hosts "$host" | awk '{print $1}' | head -n 1 || true)
    fi

    if [ -z "$resolved_ip" ]; then
        resolved_ip=$(ping -c 1 "$host" 2>/dev/null | head -n 1 | awk -F'[()]' '{print $2}' || true)
    fi

    if [ "$host" = "localhost" ] && [ -z "$resolved_ip" ]; then
        resolved_ip="127.0.0.1"
    fi

    if [ -z "$resolved_ip" ]; then
        echo "Error: Hostname '$host' could not be resolved." >&2
        exit 1
    fi

    echo "Resolved IP: $resolved_ip"

    echo -n "Ping Status: "
    if ping -c 2 "$host" >/dev/null 2>&1 || ping -c 2 -W 2 "$host" >/dev/null 2>&1; then
        echo "SUCCESS"
    else
        echo "FAILED (Host unreachable)"
        exit 1
    fi

    echo "=========================================="
    exit 0
}

cmd_disk() {
    echo "=========================================="
    echo "           DISK DIAGNOSTICS               "
    echo "=========================================="
    df -h /
    echo "=========================================="
    exit 0
}

MAIN_CMD="${1:-}"

case "$MAIN_CMD" in
    system)
        cmd_system
        ;;
    network)
        shift
        cmd_network "$@"
        ;;
    disk)
        cmd_disk
        ;;
    help|--help|-h)
        usage
        exit 0
        ;;
    "")
        echo "Error: Missing command argument." >&2
        usage
        exit 2
        ;;
    *)
        echo "Error: Invalid command '$MAIN_CMD'." >&2
        usage
        exit 2
        ;;
esac
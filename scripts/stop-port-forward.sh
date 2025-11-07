#!/bin/bash
set -e

PID_FILE="/tmp/all-portforwards.pid"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    
    if kill -0 "$PID" 2>/dev/null; then
        echo "stopping all port-forwards (PID $PID)..."
        kill "$PID"
        sleep 2
    else
        echo "no running process found with PID $PID"
    fi

    rm -f "$PID_FILE"
    echo "cleanup complete."
else
    echo "PID file $PID_FILE doesn't exist!"
fi

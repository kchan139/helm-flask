#!/bin/bash
set -e

PID_FILE="/tmp/traefik-portforward.pid"

if [ ! -f "$PID_FILE" ]; then
    exit 1
fi

kill "$(cat "$PID_FILE")"
rm "$PID_FILE"
echo "Port-forward stopped"

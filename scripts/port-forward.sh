#!/bin/bash
set -e

LOCAL_PORT=8000
REMOTE_PORT=80
NAMESPACE="kube-system"
SERVICE="traefik"
PID_FILE="/tmp/traefik-portforward.pid"

echo "--- STARTING PORT-FORWARD ---"

if nohup kubectl -n "$NAMESPACE" port-forward svc/"$SERVICE" "$LOCAL_PORT":"$REMOTE_PORT" >/dev/null 2>&1 & then
    echo $! > "$PID_FILE"
    echo "Port-forward started: $LOCAL_PORT → $REMOTE_PORT (PID $(cat $PID_FILE))"
else
    exit 1
fi

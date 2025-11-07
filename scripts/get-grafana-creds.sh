#!/bin/bash
set -euo pipefail

NAMESPACE=${1:-monitoring}
SECRET=${2:-prometheus-grafana}

echo "! WARNING: This will print Grafana admin credentials to your terminal as plain text"

read -rp "Proceed? [y/n] " ans

case "$ans" in
  'y'|'Y') ;;
  *) echo; echo "--- Cancelled ---"; exit 1;;
esac

kubectl -n "$NAMESPACE" get secret "$SECRET" -o jsonpath='{.data.admin-user}' | base64 --decode; echo
kubectl -n "$NAMESPACE" get secret "$SECRET" -o jsonpath='{.data.admin-password}' | base64 --decode; echo

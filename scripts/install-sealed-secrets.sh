#!/bin/bash
set -e

echo "--- Installing Sealed Secrets Controller ---"

helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update

helm upgrade --install sealed-secrets-controller \
  --namespace kube-system \
  --set-string fullnameOverride=sealed-secrets-controller \
  sealed-secrets/sealed-secrets

echo " ✔ COMPLETED"

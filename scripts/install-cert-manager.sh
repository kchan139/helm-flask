#!/bin/bash
set -e

echo "--- Installing cert-manager ---"

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

echo " ✔ Cert-Manager installed"

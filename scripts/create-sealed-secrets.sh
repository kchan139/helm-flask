#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENV=${1:-dev}

# validate input
if [[ ! $ENV =~ ^(dev|staging|prod)$ ]]; then
    echo " ✘ ERROR! Invalid environment $ENV"
    echo "usage: $0 [ dev | staging | prod ]"
    exit 1
fi

read -p "DB_NAME (default: appdb): " DB_NAME
DB_NAME=${DB_NAME:-appdb}
read -p "DB_USER (default: postgres): " DB_USER
DB_USER=${DB_USER:-postgres}
read -sp "DB_PASSWORD: " DB_PASSWORD
echo

if [ -z "$DB_PASSWORD" ]; then
  echo "ERROR: DB_PASSWORD cannot be empty"
  exit 1
fi

echo
echo "--- Creating sealed secret ---"

# create temporary secret
kubectl create secret generic postgres-secret \
  --namespace="$ENV" \
  --from-literal=DB_NAME="$DB_NAME" \
  --from-literal=DB_USER="$DB_USER" \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  --dry-run=client -o yaml > /tmp/secret.yaml

# encrypt using kubeseal
kubeseal --format=yaml \
  --namespace="$ENV" \
  < /tmp/secret.yaml > "$PROJECT_ROOT/helm/charts/database/templates/sealedsecret.yml"

# cleanup previously created secret
rm /tmp/secret.yaml

echo " ✔ Sealed secret created at helm/charts/database/templates/sealedsecret.yml"

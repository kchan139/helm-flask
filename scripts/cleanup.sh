#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENV=${1:-dev}

# validate input
if [[ ! $ENV =~ ^(dev|staging|prod)$ ]]; then
    echo "ERROR! Invalid environment $ENV"
    echo "usage: $0 [dev|staging|prod]"
    exit 1
fi

echo "--- Cleaning things up ---"

VALUES_FILE="$PROJECT_ROOT/helm/values-$ENV.yaml"
NAMESPACE=$(grep ^namespace $VALUES_FILE | awk '{print $2}')

helm uninstall app -n $NAMESPACE

kubectl scale deployment --all --replicas=0 -n monitoring
kubectl scale statefulset --all --replicas=0 -n monitoring
echo
echo "--- Completed ---"

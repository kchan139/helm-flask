#!/bin/bash

PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENV=${1:-dev}

# validate input
if [[ ! $ENV =~ ^(dev|staging|prod)$ ]]; then
    echo "ERROR! Invalid environment $ENV"
    echo "usage: $0 [dev|staging|prod]"
    exit 1
fi

echo "--- Cleaning things up ---"
echo

VALUES_FILE="$PROJECT_ROOT/helm/values-$ENV.yaml"
NAMESPACE=$(grep ^namespace $VALUES_FILE | awk '{print $2}')

helm uninstall app -n $NAMESPACE &>/dev/null
echo "release \"app\" uninstalled"

kubectl scale deployment --all --replicas=0 -n monitoring 2>/dev/null
kubectl scale statefulset --all --replicas=0 -n monitoring 2>/dev/null
echo
echo "--- Completed ---"

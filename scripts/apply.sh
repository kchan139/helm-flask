#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)

ENV=${1:-dev} # Default to 'dev'

# validate input
if [[ ! $ENV =~ ^(dev|staging|prod)$ ]]; then
    echo "ERROR! Invalid environment $ENV"
    echo "usage: $0 [dev|staging|prod]"
    exit 1
fi

VALUES_FILE="$PROJECT_ROOT/helm/values-$ENV.yaml"

NAMESPACE=$(grep ^namespace $VALUES_FILE | awk '{print $2}')

echo "--- Deploying to $ENV ---"
echo "using namespace: $NAMESPACE"
echo

helm upgrade --install app helm/ \
    -f $VALUES_FILE \
    -n $NAMESPACE \
    --create-namespace

sleep 0.25
echo
echo "---"
helm ls -n $NAMESPACE

sleep 0.25
echo
echo "---"
kubectl get po -n $NAMESPACE

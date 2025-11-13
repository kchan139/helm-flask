#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENV=${1:-dev}

if [[ ! $ENV =~ ^(dev|staging|prod)$ ]]; then
    echo "ERROR! Invalid environment $ENV"
    echo "usage: $0 [dev|staging|prod]"
    exit 1
fi

VALUES_FILE="$PROJECT_ROOT/helm/values-$ENV.yaml"
NAMESPACE=$(grep ^namespace $VALUES_FILE | awk '{print $2}')

watch -n1 "
echo '---'
kubectl get po -n $NAMESPACE
echo
echo '---'
kubectl get hpa -n $NAMESPACE
"

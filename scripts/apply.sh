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

VALUES_FILE="$PROJECT_ROOT/helm/values-$ENV.yaml"

NAMESPACE=$(grep ^namespace $VALUES_FILE | awk '{print $2}')

echo "--- Deploying to $ENV ---"
echo

# load .env for email
if [[ "$ENV" == "prod" || "$ENV" == "staging" ]]; then
    source "$PROJECT_ROOT/.env"
fi

# check if email is set
SET_ARGS=""
if [ -n "$SSL_EMAIL" ]; then
    echo "using: $SSL_EMAIL"
    SET_ARGS="--set certManager.email=$SSL_EMAIL"
fi

helm upgrade --install app helm/ \
    -f $VALUES_FILE \
    -n $NAMESPACE \
    --create-namespace \
    $SET_ARGS

echo
echo "--- Waiting for pods ---"

# wait 20s
if ! kubectl wait --for=condition=ready pod --all -n "$NAMESPACE" --timeout=20s; then
    echo
    echo "---"
    kubectl get po -n "$NAMESPACE"
    exit 1
fi

echo
echo " ✔ COMPLETED"
echo
echo "---"
helm ls -n $NAMESPACE

echo
echo "---"
kubectl get po -n $NAMESPACE

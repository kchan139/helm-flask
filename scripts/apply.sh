#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
NAMESPACE=$(grep ^namespace $PROJECT_ROOT/helm/values.yaml | awk '{print $2}')

helm upgrade --install app helm/ -n $NAMESPACE --create-namespace

sleep 0.25
echo
echo "---"
helm ls -n $NAMESPACE

sleep 0.25
echo
echo "---"
kubectl get po -n $NAMESPACE

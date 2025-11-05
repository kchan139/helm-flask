#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
NAMESPACE=$(grep ^namespace $PROJECT_ROOT/helm/values.yaml | awk '{print $2}')

watch -n1 "kubectl get po -n $NAMESPACE"

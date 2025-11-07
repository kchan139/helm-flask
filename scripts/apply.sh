#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)
ENV="dev"
UPDATE_MONITORING=false

# parse arguments
for arg in "$@"; do
  case $arg in
    --update-monitoring)
      UPDATE_MONITORING=true
      ;;
    dev|staging|prod)
      ENV=$arg
      ;;
    *)
      echo "ERROR! Unknown argument: $arg"
      echo "usage: $0 [dev|staging|prod] [--update-monitoring]"
      exit 1
      ;;
  esac
done

# validate input
if [[ ! $ENV =~ ^(dev|staging|prod)$ ]]; then
    echo "ERROR! Invalid environment $ENV"
    echo "usage: $0 [dev|staging|prod] [--update-monitoring]"
    exit 1
fi

VALUES_FILE="$PROJECT_ROOT/helm/values-$ENV.yaml"

NAMESPACE=$(grep ^namespace $VALUES_FILE | awk '{print $2}')


if [ $UPDATE_MONITORING = true ]; then
    echo "--- Installing monitoring stack ---"

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
      --namespace monitoring \
      --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
      --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
      --set prometheus.prometheusSpec.ruleSelectorNilUsesHelmValues=false

    echo "--- Monitoring stack installed/updated ---"
    echo
fi

echo "--- Deploying to $ENV ---"
echo "using namespace: $NAMESPACE"
echo

helm upgrade --install app helm/ \
    -f $VALUES_FILE \
    -n $NAMESPACE \
    --create-namespace

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
echo "---"
helm ls -n $NAMESPACE

echo
echo "---"
kubectl get po -n $NAMESPACE

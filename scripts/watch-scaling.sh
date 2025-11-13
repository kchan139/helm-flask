#!/bin/bash
set -e

PROJECT_ROOT=$(git rev-parse --show-toplevel)

watch -n 0.5 bash -c "
echo
for ENV in dev staging prod; do
  VALUES_FILE=\"$PROJECT_ROOT/helm/values-\$ENV.yaml\"

  NAMESPACE=\$(grep ^namespace \$VALUES_FILE | awk '{print \$2}')
  echo '  --- Watching' \$ENV '---  '
  
  kubectl get po -n \$NAMESPACE
  echo
  kubectl get hpa -n \$NAMESPACE 2>/dev/null

  echo
done
"


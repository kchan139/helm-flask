#!/bin/bash
set -e

PROJECT_ROOT=$(dirname "$(realpath "$0")")/../
IMAGE_TAG=${1:-latest}

# detect container engine
if command -v podman &> /dev/null; then
    TOOL=podman
elif command -v docker &> /dev/null; then
    TOOL=docker
else
    echo "Error: podman or docker is not installed." >&2
    exit 1
fi

echo
echo "--- Building Flask App ---"
$TOOL build -t localhost/flask-app:$IMAGE_TAG "$PROJECT_ROOT/backend"
$TOOL save localhost/flask-app:$IMAGE_TAG | sudo k3s ctr images import -

echo
echo "--- Building Postgres DB ---"
$TOOL build -t localhost/db:$IMAGE_TAG "$PROJECT_ROOT/database"
$TOOL save localhost/db:$IMAGE_TAG | sudo k3s ctr images import -

echo
echo "---"
echo "BUILD SUCCEEDED"

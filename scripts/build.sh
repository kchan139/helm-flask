#!/bin/bash
set -e

PROJECT_ROOT=$(dirname "$(realpath "$0")")/../

# Detect container tool
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
$TOOL build -t localhost/flask-app:latest "$PROJECT_ROOT/backend"
$TOOL save localhost/flask-app:latest | sudo k3s ctr images import -

# echo
# echo "--- Importing Flask App ---"
# $TOOL save localhost/flask-app:latest -o /tmp/flask.tar
# sudo k3s ctr images import /tmp/flask.tar
# rm /tmp/flask.tar

echo
echo "--- Building Postgres DB ---"
$TOOL build -t localhost/db:latest "$PROJECT_ROOT/database"
$TOOL save localhost/db:latest | sudo k3s ctr images import -

# echo
# echo "--- Importing Postgres DB ---"
# $TOOL save localhost/db:latest -o /tmp/db.tar
# sudo k3s ctr images import /tmp/db.tar
# rm /tmp/db.tar

echo
echo "---"
echo "BUILD SUCCEEDED"

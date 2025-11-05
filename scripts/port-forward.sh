#!/bin/bash
set -e

nohup kubectl -n kube-system port-forward svc/traefik 8000:80 > /tmp/traefik-portforward.log 2>&1 &
echo $! > /tmp/traefik-portforward.pid

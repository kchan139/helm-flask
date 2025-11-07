#!/bin/bash
set -e

echo "--- STARTING PORT-FORWARD ---"

# start all port-forwards in a single nohup session
nohup bash -c '
  # traefik
  kubectl -n kube-system port-forward svc/traefik 8000:80 > /tmp/traefik-portforward.log 2>&1 &
  
  # grafana
  kubectl -n monitoring port-forward svc/prometheus-grafana 3000:80 > /tmp/grafana-portforward.log 2>&1 &
  
  # prometheus
  kubectl -n monitoring port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 > /tmp/prometheus-portforward.log 2>&1 &
  
  # wait for background processes
  wait
' > /tmp/all-portforwards.log 2>&1 &

echo $! > /tmp/all-portforwards.pid
echo "all port-forwards started (PID $(cat /tmp/all-portforwards.pid))"


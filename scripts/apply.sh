#!/bin/bash

helm upgrade --install app helm/ -n demo --create-namespace

echo
echo "---"
helm ls -n demo

echo
echo "---"
kubectl get po -n demo

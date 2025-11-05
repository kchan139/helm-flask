#!/bin/bash
set -e 

for i in {1..5}; do
  curl "http://localhost:8000/stress?duration=120" &
done

#!/bin/bash
hey -z 20s -c 5 http://localhost:8000

# DURATION=${1:-30}  # default 30s
# RATE_LIMIT=0.01
# END_TIME=$((SECONDS + DURATION))

# while [ $SECONDS -lt $END_TIME ]; do
#   curl -s localhost:8000 > /dev/null || echo " ✘ request failed"
#   sleep $RATE_LIMIT
# done

#!/bin/bash

set -e

kill $(cat /tmp/traefik-portforward.pid)
rm /tmp/traefik-portforward.pid

#!/bin/bash -e

# `init` hook
# $1 = operation (either `join`, `boot` or `orchestrate`)

echo "Starting $1 operation"

docker kill nodeos-bios || true
docker rm nodeos-bios || true

docker -H 10.10.0.54:5555 kill fullnode || true
docker -H 10.10.0.54 rm:5555 fullnode || true

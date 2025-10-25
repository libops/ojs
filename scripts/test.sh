#!/usr/bin/env bash

set -eou pipefail

max_attempts=10
attempt=0

while [ $attempt -lt $max_attempts ]; do
  attempt=$(( attempt + 1 ))
  echo "Attempt $attempt of $max_attempts..."

  sleep 60

  if curl -sf http://localhost | grep "<img" | grep -q "Open Journal Systems"; then
    echo "OJS is up!"
    exit 0
  fi
done

echo "Failed to detect OJS after $max_attempts attempts"
exit 1

#!/usr/bin/env bash

set -eou pipefail

docker compose build --pull
./scripts/init-if-needed.sh
docker compose up --remove-orphans -d

max_attempts=20
attempt=0
target_url="${SITE_URL:-http://localhost/}"

while [ $attempt -lt $max_attempts ]; do
  attempt=$(( attempt + 1 ))
  echo "Attempt $attempt of $max_attempts..."

  sleep 10

  if curl -sf "$target_url" | grep "<img" | grep -q "Open Journal Systems"; then
    echo "OJS is up!"
    exit 0
  fi
  sleep 30
  docker compose logs ojs --tail 20
done

docker compose logs ojs

echo "Failed to detect OJS after $max_attempts attempts"
exit 1

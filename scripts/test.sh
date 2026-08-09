#!/usr/bin/env bash

set -eou pipefail

docker compose build --pull
docker compose run --rm init

docker compose run --rm --entrypoint /usr/local/bin/validate-ojs-secret-key.sh init

docker compose up --remove-orphans --wait --wait-timeout "${COMPOSE_WAIT_TIMEOUT:-900}"

target_url="${SITE_URL:-http://localhost/}"
curl -fsS "${target_url}" | grep "<img" | grep -q "Open Journal Systems"

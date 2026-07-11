#!/usr/bin/env bash

set -eou pipefail

docker compose build --pull
docker compose run --rm init

app_key="$(<secrets/OJS_SECRET_KEY)"
encoded_app_key="${app_key#base64:}"
if [[ "${app_key}" != base64:* || ! "${encoded_app_key}" =~ ^[A-Za-z0-9+/]{43}=$ ]] ||
  ! app_key_bytes="$(printf '%s' "${encoded_app_key}" | openssl base64 -d -A 2>/dev/null | wc -c)" ||
  [ "${app_key_bytes}" -ne 32 ]; then
  echo "OJS_SECRET_KEY must be a base64-encoded 32-byte application key" >&2
  exit 1
fi

docker compose up --remove-orphans --wait --wait-timeout "${COMPOSE_WAIT_TIMEOUT:-900}"

target_url="${SITE_URL:-http://localhost/}"
curl -fsS "${target_url}" | grep "<img" | grep -q "Open Journal Systems"

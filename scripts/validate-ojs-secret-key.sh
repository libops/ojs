#!/usr/bin/env bash

set -euo pipefail

secret_key_file="${OJS_SECRET_KEY_FILE:-/work/secrets/OJS_SECRET_KEY}"

app_key="$(<"$secret_key_file")"
encoded_app_key="${app_key#base64:}"
if [[ "$app_key" != base64:* || ! "$encoded_app_key" =~ ^[A-Za-z0-9+/]{43}=$ ]] ||
  ! app_key_bytes="$(printf '%s' "$encoded_app_key" | openssl base64 -d -A 2>/dev/null | wc -c)" ||
  [ "$app_key_bytes" -ne 32 ]; then
  echo "OJS_SECRET_KEY must be a base64-encoded 32-byte application key" >&2
  exit 1
fi

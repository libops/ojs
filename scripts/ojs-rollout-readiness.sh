#!/usr/bin/env sh

set -eu

attempt=0
max_attempts="${OJS_ROLLOUT_MAX_ATTEMPTS:-150}"

until test -f /installed; do
  attempt=$((attempt + 1))
  if test "$attempt" -ge "$max_attempts"; then
    echo "OJS did not become ready for database migration within 5 minutes" >&2
    exit 1
  fi
  sleep 2
done

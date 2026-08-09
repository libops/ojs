#!/usr/bin/env bash

set -euo pipefail

readonly config_probe=/usr/local/share/libops/sitectl-ojs-database-config.php
readonly query_file=/usr/local/share/libops/sitectl-ojs-verify.sql

# shellcheck source=/dev/null
. /usr/local/share/libops/database.sh

mapfile -d '' -t database < <(php "$config_probe")
if [ "${#database[@]}" -ne 5 ]; then
  echo 'could not read database credentials from config.inc.php' >&2
  exit 2
fi

database_mariadb_with_password "${database[3]}" \
  --host="${database[0]}" \
  --port="${database[1]}" \
  --user="${database[2]}" \
  --database="${database[4]}" \
  --batch \
  --skip-column-names < "$query_file"

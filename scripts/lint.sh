#!/usr/bin/env bash

set -euo pipefail

service="${COMPOSE_SERVICE:-ojs}"
image="$(docker compose config --format json | jq -r --arg service "${service}" '.services[$service].image // empty')"

if [ -z "${image}" ]; then
  echo "Compose service ${service} does not define an image" >&2
  exit 1
fi

case "${image}" in
  *libops*) ;;
  *)
    echo "Expected ${service} image to be a libops image, got ${image}" >&2
    exit 1
    ;;
esac

if command -v hadolint >/dev/null 2>&1; then
  echo "Running hadolint on Dockerfiles..."
  find . -name Dockerfile -exec hadolint {} +
else
  echo "hadolint not found, skipping Dockerfile validation"
fi

if command -v json5 >/dev/null 2>&1 && [ -f renovate.json5 ]; then
  echo "Running json5 validation on renovate.json5"
  json5 --validate renovate.json5 >/dev/null
else
  echo "json5 not found or renovate.json5 missing, skipping renovate validation"
fi

if command -v shellcheck >/dev/null 2>&1; then
  find scripts -name "*.sh" -exec shellcheck {} +
else
  find scripts -name "*.sh" -exec bash -n {} +
fi

docker compose build --pull "${service}"

docker run --rm \
  --volume "${PWD}:/workspace:ro" \
  --workdir /workspace \
  --entrypoint sh \
  "${image}" \
  -lc '
    set -eu

    if [ ! -d plugins ]; then
      echo "No custom OJS plugins directory found; skipping OJS PHP lint."
      exit 0
    fi

    if ! find plugins -type f \( -name "*.php" -o -name "*.inc.php" \) | grep -q .; then
      echo "No custom OJS PHP files found; skipping OJS PHP lint."
      exit 0
    fi

    find plugins -type f \( -name "*.php" -o -name "*.inc.php" \) -exec php -l {} \;
  '

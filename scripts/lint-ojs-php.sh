#!/usr/bin/env sh

set -eu

found=0
for root in "$@"; do
  if test ! -d "$root"; then
    continue
  fi
  if find "$root" -type f \( -name '*.php' -o -name '*.inc.php' \) | grep -q .; then
    find "$root" -type f \( -name '*.php' -o -name '*.inc.php' \) -exec php -l {} \;
    found=1
  fi
done

if test "$found" -eq 0; then
  echo 'No custom OJS PHP files found; skipping OJS PHP lint.'
fi

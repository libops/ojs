#!/usr/bin/env sh

set -eu

private_root=/var/www/files
public_root=/var/www/ojs/public

test -r "$private_root"
test -w "$private_root"
test -r "$public_root"
test -w "$public_root"

if test "${1:-}" != "--disposable"; then
  echo 'storage writable'
  exit 0
fi

private="$private_root/.sitectl-verify-$$"
public="$public_root/.sitectl-verify-$$"

cleanup() {
  rm -f -- "$private" "$public"
}
trap cleanup EXIT INT TERM

printf '%s' sitectl-verify > "$private"
printf '%s' sitectl-verify > "$public"
test "$(cat "$private")" = sitectl-verify
test "$(cat "$public")" = sitectl-verify

cleanup
trap - EXIT INT TERM
echo 'storage round trip complete'

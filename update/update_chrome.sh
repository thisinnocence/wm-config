#!/bin/sh

set -eu

green="$(printf '\033[32m')"
yellow="$(printf '\033[33m')"
reset="$(printf '\033[0m')"

old_version="$(google-chrome-stable --version 2>/dev/null || true)"

sudo apt-get update
sudo apt-get install --only-upgrade -y google-chrome-stable

new_version="$(google-chrome-stable --version 2>/dev/null || true)"

printf 'Old version: %s%s%s\n' "$yellow" "${old_version:-unknown}" "$reset"
printf 'New version: %s%s%s\n' "$green" "${new_version:-unknown}" "$reset"

if [ "$old_version" = "$new_version" ]; then
  printf 'Status: %sunchanged%s\n' "$yellow" "$reset"
else
  printf 'Status: %supdated%s\n' "$green" "$reset"
fi

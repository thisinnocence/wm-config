#!/usr/bin/env bash
set -euo pipefail

REPO="clash-verge-rev/clash-verge-rev"
PACKAGE_NAME="clash-verge"

green="$(printf '\033[32m')"
yellow="$(printf '\033[33m')"
reset="$(printf '\033[0m')"

old_version="$(dpkg-query -W -f='${Version}\n' "$PACKAGE_NAME" 2>/dev/null || true)"
printf 'Installed version: %s%s%s\n' "$yellow" "${old_version:-not installed}" "$reset"

was_running=0
if pgrep -x clash-verge >/dev/null 2>&1; then
  was_running=1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

api_url="https://api.github.com/repos/${REPO}/releases/latest"
release_json="${tmp_dir}/latest-release.json"

echo "Fetching latest release metadata: $api_url"
curl -fsSL "$api_url" -o "$release_json"

deb_url="$(
  grep '"browser_download_url":' "$release_json" \
    | sed -E 's/.*"([^"]+)".*/\1/' \
    | grep '/Clash\.Verge_.*_amd64\.deb$' \
    | head -n1
)"

if [[ -z "$deb_url" ]]; then
  echo "Could not find official amd64 .deb asset in latest release." >&2
  exit 1
fi

deb_name="$(basename "$deb_url")"
deb_path="${tmp_dir}/${deb_name}"

echo "Downloading: $deb_url"
curl -fL "$deb_url" -o "$deb_path"

deb_version="$(dpkg-deb -f "$deb_path" Version 2>/dev/null || true)"
printf 'Package version: %s%s%s\n' "$yellow" "${deb_version:-unknown}" "$reset"

if [[ "$was_running" -eq 1 ]]; then
  echo "Stopping running Clash Verge..."
  pkill -x clash-verge || true
  sleep 2
fi

sudo apt-get install -y "$deb_path"

if [[ "$was_running" -eq 1 ]]; then
  echo "Restarting Clash Verge..."
  nohup /usr/bin/clash-verge >/dev/null 2>&1 &
fi

new_version="$(dpkg-query -W -f='${Version}\n' "$PACKAGE_NAME" 2>/dev/null || true)"
printf 'New version: %s%s%s\n' "$green" "${new_version:-unknown}" "$reset"

if [[ "$old_version" = "$new_version" ]]; then
  printf 'Status: %sunchanged%s\n' "$yellow" "$reset"
else
  printf 'Status: %supdated%s\n' "$green" "$reset"
fi

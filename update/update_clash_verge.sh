#!/usr/bin/env bash
set -euo pipefail

# 安装或更新 Clash Verge：
# - 通过 GitHub API 获取最新正式版，并用 jq 选择 amd64 架构的 DEB 包；
# - 使用 APT 安装下载的软件包，因此需要网络连接、jq 和 sudo 权限；
# - 若 Clash Verge 原本正在运行，安装前将其停止，并在安装后重新启动。

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

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse GitHub release metadata." >&2
  exit 1
fi

echo "Fetching latest release metadata: $api_url"
curl -fsSL "$api_url" -o "$release_json"

deb_url="$(
  jq -r '
    first(
      .assets[]?.browser_download_url
      | select(test("/Clash\\.Verge_.*_amd64\\.deb$"))
    ) // empty
  ' "$release_json"
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

#!/usr/bin/env bash
set -euo pipefail

# 安装或更新 Clash Verge：
# - 通过 GitHub API 获取最新正式版，并用 jq 选择 amd64 架构的 DEB 包；
# - 校验 GitHub 提供的 SHA-256、DEB 包名和架构，再通过 APT 安装；
# - 脚本必须由普通用户运行，仅 APT 安装步骤使用 sudo；
# - 若当前用户的 Clash Verge 原本正在运行，安装失败或成功后都会尝试恢复运行。

REPO="clash-verge-rev/clash-verge-rev"
PACKAGE_NAME="clash-verge"
EXPECTED_ARCH="amd64"

green="$(printf '\033[32m')"
yellow="$(printf '\033[33m')"
reset="$(printf '\033[0m')"

if (( EUID == 0 )); then
  echo "error: do not run this script with sudo or as root" >&2
  exit 1
fi

old_version="$(dpkg-query -W -f='${Version}\n' "$PACKAGE_NAME" 2>/dev/null || true)"
was_installed=0
if dpkg-query -W -f='${Status}\n' "$PACKAGE_NAME" 2>/dev/null \
  | grep -qx 'install ok installed'; then
  was_installed=1
fi
printf 'Installed version: %s%s%s\n' "$yellow" "${old_version:-not installed}" "$reset"

was_running=0
process_stopped=0
process_restarted=0
user_id="$(id -u)"
if pgrep -u "$user_id" -x clash-verge >/dev/null 2>&1; then
  was_running=1
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  local status=$?
  trap - EXIT

  if [[ "$was_running" -eq 1 && "$process_stopped" -eq 1 && "$process_restarted" -eq 0 ]]; then
    echo "Restoring Clash Verge after an interrupted update..." >&2
    nohup /usr/bin/clash-verge >/dev/null 2>&1 &
  fi

  rm -rf "$tmp_dir"
  exit "$status"
}
trap cleanup EXIT

api_url="https://api.github.com/repos/${REPO}/releases/latest"
release_json="${tmp_dir}/latest-release.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse GitHub release metadata." >&2
  exit 1
fi

echo "Fetching latest release metadata: $api_url"
curl -fsSL "$api_url" -o "$release_json"

asset_info="$(
  jq -er '
    first(
      .assets[]?
      | select(.browser_download_url | test("/Clash\\.Verge_.*_amd64\\.deb$"))
    )
    | [.browser_download_url, .digest]
    | @tsv
  ' "$release_json" || true
)"
IFS=$'\t' read -r deb_url deb_digest <<< "$asset_info"

if [[ -z "$deb_url" || ! "$deb_digest" =~ ^sha256:[0-9a-fA-F]{64}$ ]]; then
  echo "Could not find an official amd64 DEB asset with a SHA-256 digest." >&2
  exit 1
fi

deb_name="$(basename "$deb_url")"
deb_path="${tmp_dir}/${deb_name}"

echo "Downloading: $deb_url"
curl -fL "$deb_url" -o "$deb_path"

printf '%s  %s\n' "${deb_digest#sha256:}" "$deb_path" | sha256sum --check --status

deb_package="$(dpkg-deb -f "$deb_path" Package)"
deb_arch="$(dpkg-deb -f "$deb_path" Architecture)"
deb_version="$(dpkg-deb -f "$deb_path" Version)"
if [[ "$deb_package" != "$PACKAGE_NAME" ]]; then
  echo "Unexpected DEB package name: $deb_package" >&2
  exit 1
fi
if [[ "$deb_arch" != "$EXPECTED_ARCH" ]]; then
  echo "Unexpected DEB architecture: $deb_arch" >&2
  exit 1
fi
printf 'Package version: %s%s%s\n' "$yellow" "${deb_version:-unknown}" "$reset"

if [[ "$was_running" -eq 1 ]]; then
  echo "Stopping running Clash Verge..."
  pkill -u "$user_id" -x clash-verge || true
  process_stopped=1
  sleep 2
fi

sudo apt-get install -y "$deb_path"

if [[ "$was_running" -eq 1 ]]; then
  echo "Restarting Clash Verge..."
  nohup /usr/bin/clash-verge >/dev/null 2>&1 &
  process_restarted=1
fi

new_version="$(dpkg-query -W -f='${Version}\n' "$PACKAGE_NAME" 2>/dev/null || true)"
printf 'New version: %s%s%s\n' "$green" "${new_version:-unknown}" "$reset"

if [[ "$was_installed" -eq 0 ]]; then
  printf 'Status: %sinstalled%s\n' "$green" "$reset"
elif [[ "$old_version" = "$new_version" ]]; then
  printf 'Status: %sunchanged%s\n' "$yellow" "$reset"
else
  printf 'Status: %supdated%s\n' "$green" "$reset"
fi

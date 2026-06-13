#!/usr/bin/env bash
# 任一命令失败、使用未定义变量或管道中任一环节失败时立即退出。
set -euo pipefail

# 安装或更新 Clash Verge：
# - 通过 GitHub API 获取最新正式版，并用 jq 选择 amd64 架构的 DEB 包；
# - 本地版本与最新 release 相同时跳过下载和安装；
# - 校验 GitHub 提供的 SHA-256、DEB 包名和架构，再通过 APT 安装；
# - 脚本必须由普通用户运行，仅 APT 安装步骤使用 sudo；
# - 若当前用户的 Clash Verge 原本正在运行，安装失败或成功后都会尝试恢复运行。

REPO="clash-verge-rev/clash-verge-rev"
PACKAGE_NAME="clash-verge"
EXPECTED_ARCH="amd64"

green="$(printf '\033[32m')"
yellow="$(printf '\033[33m')"
reset="$(printf '\033[0m')"

old_version=""
new_version=""
was_installed=0
was_running=0
process_stopped=0
process_restarted=0
user_id=""
tmp_dir=""
deb_url=""
deb_digest=""
deb_path=""
deb_version=""
release_tag=""
release_version=""

cleanup() {
  # 先保存触发 EXIT trap 的原始退出码，否则后续命令会覆盖 $?。
  local status=$?
  # trap 用于指定 Shell 收到信号或发生退出等事件时要执行的命令。
  # 取消通过 `trap cleanup EXIT` 注册的退出处理，避免下面的 exit 再次调用 cleanup。
  trap - EXIT

  if [[ "$was_running" -eq 1 && "$process_stopped" -eq 1 && "$process_restarted" -eq 0 ]]; then
    echo "Restoring Clash Verge after an interrupted update..." >&2
    # nohup 配合后台运行，使程序不依赖当前终端；输出全部丢弃。
    nohup /usr/bin/clash-verge >/dev/null 2>&1 &
  fi

  rm -rf "$tmp_dir"
  exit "$status"
}

preflight() {
  if (( EUID == 0 )); then
    echo "error: do not run this script with sudo or as root" >&2
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to parse GitHub release metadata." >&2
    exit 1
  fi
}

detect_current_state() {
  old_version="$(dpkg-query -W -f='${Version}\n' "$PACKAGE_NAME" 2>/dev/null || true)"

  # dpkg-query 未找到软件包时会失败；放在 if 条件中可安全地按“未安装”处理。
  if dpkg-query -W -f='${Status}\n' "$PACKAGE_NAME" 2>/dev/null \
    | grep -qx 'install ok installed'; then
    was_installed=1
  fi
  printf 'Installed version: %s%s%s\n' "$yellow" "${old_version:-not installed}" "$reset"

  user_id="$(id -u)"
  if pgrep -u "$user_id" -x clash-verge >/dev/null 2>&1; then
    was_running=1
  fi
}

create_workspace() {
  tmp_dir="$(mktemp -d)"
  trap cleanup EXIT
}

fetch_release_asset() {
  local api_url="https://api.github.com/repos/${REPO}/releases/latest"
  local release_json="${tmp_dir}/latest-release.json"
  local asset_info

  echo "Fetching latest release metadata: $api_url"
  curl -fsSL "$api_url" -o "$release_json"

  asset_info="$(
    # jq 是用于解析、筛选和转换 JSON 数据的命令行工具。
    # first 只取首个匹配资源；[]? 在 assets 缺失或为空时不会让 jq 报错。
    # @tsv 将下载地址、摘要和 release 标签以制表符分隔，供下面的 read 拆分。
    jq -er '
      . as $release
      | first(
        $release.assets[]?
        | select(.browser_download_url | test("/Clash\\.Verge_.*_amd64\\.deb$"))
      )
      | [.browser_download_url, .digest, $release.tag_name]
      | @tsv
    ' "$release_json" || true
  )"
  # 仅为本次 read 将字段分隔符设为制表符；<<< 把字符串作为标准输入传入。
  IFS=$'\t' read -r deb_url deb_digest release_tag <<< "$asset_info"

  # =~ 使用 Bash 正则，确认摘要严格为“sha256:”加 64 位十六进制字符。
  if [[ -z "$deb_url" || -z "$release_tag" || ! "$deb_digest" =~ ^sha256:[0-9a-fA-F]{64}$ ]]; then
    echo "Could not find an official amd64 DEB asset with a SHA-256 digest." >&2
    exit 1
  fi

  # GitHub 标签通常以 v 开头，而 DEB 版本不带 v。
  release_version="${release_tag#v}"
  deb_path="${tmp_dir}/$(basename "$deb_url")"
}

is_up_to_date() {
  [[ "$was_installed" -eq 1 ]] \
    && dpkg --compare-versions "$old_version" eq "$release_version"
}

print_up_to_date() {
  printf 'Clash Verge 已经是最新版本: %s%s%s\n' \
    "$green" "$release_version" "$reset"
}

download_and_verify_deb() {
  local deb_package
  local deb_arch

  echo "Downloading: $deb_url"
  curl -fL "$deb_url" -o "$deb_path"

  # ${deb_digest#sha256:} 删除最短的前缀匹配，得到 sha256sum 所需的纯摘要。
  printf '%s  %s\n' "${deb_digest#sha256:}" "$deb_path" | sha256sum --check --status

  # 不只信任文件名：直接读取 DEB 控制信息，核对包名、架构和版本。
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
}

stop_clash_verge() {
  if [[ "$was_running" -eq 0 ]]; then
    return
  fi

  echo "Stopping running Clash Verge..."
  pkill -u "$user_id" -x clash-verge || true
  process_stopped=1
  sleep 2
}

install_package() {
  stop_clash_verge
  sudo apt-get install -y "$deb_path"

  if [[ "$was_running" -eq 1 ]]; then
    echo "Restarting Clash Verge..."
    nohup /usr/bin/clash-verge >/dev/null 2>&1 &
    process_restarted=1
  fi
}

print_result() {
  new_version="$(dpkg-query -W -f='${Version}\n' "$PACKAGE_NAME" 2>/dev/null || true)"
  printf 'New version: %s%s%s\n' "$green" "${new_version:-unknown}" "$reset"

  if [[ "$was_installed" -eq 0 ]]; then
    printf 'Status: %sinstalled%s\n' "$green" "$reset"
  elif [[ "$old_version" = "$new_version" ]]; then
    printf 'Status: %sunchanged%s\n' "$yellow" "$reset"
  else
    printf 'Status: %supdated%s\n' "$green" "$reset"
  fi
}

main() {
  preflight
  detect_current_state
  create_workspace
  fetch_release_asset

  if is_up_to_date; then
    print_up_to_date
    return
  fi

  download_and_verify_deb
  install_package
  print_result
}

main "$@"

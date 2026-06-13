#!/bin/sh

set -eu

# 安装或更新 Google Chrome Stable
# - 刷新 APT 软件源，并比较本地版本与远端候选版本
# - 已是最新版时跳过安装，否则安装或升级 google-chrome-stable
# - Chrome 软件源必须已经配置，执行安装需要 sudo 权限
# - 显示操作前后的版本，并区分首次安装、版本未变和升级成功

PACKAGE_NAME="google-chrome-stable"

green="$(printf '\033[32m')"
yellow="$(printf '\033[33m')"
reset="$(printf '\033[0m')"

old_version=""
new_version=""
installed_version=""
candidate_version=""
was_installed=0

detect_current_state() {
  old_version="$(google-chrome-stable --version 2>/dev/null || true)"
  installed_version="$(dpkg-query -W -f='${Version}\n' "$PACKAGE_NAME" 2>/dev/null || true)"

  # 查询 dpkg 状态；仅当软件包处于“已选择、状态正常、已安装”时标记为已安装
  if dpkg-query -W -f='${Status}\n' "$PACKAGE_NAME" 2>/dev/null \
    | grep -qx 'install ok installed'; then
    was_installed=1
  fi
}

refresh_package_metadata() {
  sudo apt-get update
}

detect_candidate_version() {
  # 从 APT 软件包策略中找到 Candidate 行；awk 输出第二列的候选版本后立即退出
  candidate_version="$(
    apt-cache policy "$PACKAGE_NAME" \
      | awk '/Candidate:/ { print $2; exit }'
  )"

  if [ -z "$candidate_version" ] || [ "$candidate_version" = "(none)" ]; then
    echo "error: no candidate version found for $PACKAGE_NAME" >&2
    exit 1
  fi
}

is_up_to_date() {
  [ "$was_installed" -eq 1 ] \
    && dpkg --compare-versions "$installed_version" eq "$candidate_version"
}

update_chrome() {
  sudo apt-get install -y "$PACKAGE_NAME"
}

print_up_to_date() {
  printf 'Google Chrome is already up to date: %s%s%s\n' \
    "$green" "$candidate_version" "$reset"
}

print_result() {
  new_version="$(google-chrome-stable --version 2>/dev/null || true)"

  printf 'Old version: %s%s%s\n' "$yellow" "${old_version:-unknown}" "$reset"
  printf 'New version: %s%s%s\n' "$green" "${new_version:-unknown}" "$reset"

  if [ "$was_installed" -eq 0 ]; then
    printf 'Status: %sinstalled%s\n' "$green" "$reset"
  elif [ "$old_version" = "$new_version" ]; then
    printf 'Status: %sunchanged%s\n' "$yellow" "$reset"
  else
    printf 'Status: %supdated%s\n' "$green" "$reset"
  fi
}

main() {
  detect_current_state
  refresh_package_metadata
  detect_candidate_version

  if is_up_to_date; then
    print_up_to_date
    return
  fi

  update_chrome
  print_result
}

main "$@"
